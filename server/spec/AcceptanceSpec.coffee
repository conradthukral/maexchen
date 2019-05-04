dgram = require 'dgram'
miaGame = require '../lib/miaGame'
miaServer = require '../lib/miaServer'
dice = require '../lib/dice'
{ delay, waitFor } = require './waitUtils'

timeoutForClientAnswers = 100
serverPort = 9000
game = null
server = null
enableLogging = false

setupFakeClient = (clientName) ->
	result = new FakeUdpClient serverPort, clientName
	result.enableLogging() if enableLogging
	result.sendPlayerRegistration()
	await result.receivesRegistrationConfirmation()
	result

setupSpectator = (clientName) ->
	result = new FakeUdpClient serverPort, clientName
	result.enableLogging() if enableLogging
	result.sendSpectatorRegistration()
	await result.receivesRegistrationConfirmation()
	result
		
serverAlwaysOrdersPlayersAlphabeticallyInNewRounds = ->
	game.permuteRound = (playerList) ->
		playerList.players.sort (player1, player2) ->
			return 0 if player1.name == player2.name
			if player1.name > player2.name then 1 else -1

serverRolls = (die1, die2) ->
	game.setDiceRoller new FakeDiceRoller dice.create(die1, die2)

describe 'the Mia server', ->

	beforeEach ->
		game = miaGame.createGame()
		game.setBroadcastTimeout timeoutForClientAnswers
		server = miaServer.start game, serverPort
		server.enableLogging() if enableLogging

	afterEach ->
		game.stop()
		server.shutDown()

	describe 'player setup', ->

		client = null

		beforeEach ->
			client = new FakeUdpClient serverPort

		afterEach ->
			client.shutDown()

		it 'should accept player registrations', ->
			client.sendPlayerRegistration()
			await client.receivesRegistrationConfirmation()

	describe 'round setup', ->

		client = null

		beforeEach ->
			client = await setupFakeClient 'testClient'
			game.start()

		afterEach ->
			client.shutDown()

		it 'should keep trying to start a round while nobody joins', ->
			await client.receivesOfferToJoinRound()
			await client.receivesNotificationThatRoundWasCanceled 'NO_PLAYERS'

			await client.receivesOfferToJoinRound()
	
	describe 'should not ask spectators to join rounds', ->

		player = null
		spectator = null

		beforeEach ->
			spectator = await setupSpectator 'theSpectator'
			player = await setupFakeClient 'thePlayer'
			game.start()

		afterEach ->
			spectator.shutDown()
			player.shutDown()

		it 'should not invite spectators to join rounds', ->
			await player.receivesOfferToJoinRound()
			player.joinsRound()

			await player.receivesNotificationThatRoundIsStarting 1, 'thePlayer'

			spectator.didNotReceiveOfferToJoinRound()
			await spectator.receivesNotificationThatRoundIsStarting 1, 'thePlayer'

	describe 'when only one player participates in a round', ->

		player = null

		beforeEach ->
			player = await setupFakeClient 'thePlayer'
			game.start()

		afterEach ->
			player.shutDown()

		it 'should award the player a point without playing the round', ->
			await player.receivesOfferToJoinRound()
			player.joinsRound()
			await player.receivesNotificationThatRoundIsStarting 1, 'thePlayer'
			await player.receivesNotificationThatRoundWasCanceled 'ONLY_ONE_PLAYER'
			await player.receivesScores thePlayer: 1
			
			await player.receivesOfferToJoinRound()

	describe 'previously registered player registers again', ->

		oldPlayer = newPlayer = otherPlayer = null

		beforeEach ->
			oldPlayer = await setupFakeClient 'thePlayer'
			otherPlayer = await setupFakeClient 'theOtherPlayer'
			serverRolls 3, 1
			serverAlwaysOrdersPlayersAlphabeticallyInNewRounds()
			game.start()

		afterEach ->
			oldPlayer.shutDown()
			newPlayer.shutDown()
			otherPlayer.shutDown()

		playRound = (player1, player2) ->
			await player1.isAskedToPlayATurn()
			player1.rolls()
			await player1.receivesRolledDice dice.create(3, 1)
			player1.announcesDice dice.create(6, 6)
			await player2.isAskedToPlayATurn()
			player2.wantsToSee()

		it 'should allow the new player to take the place of the old player in the next round, keeping the score', ->
			await otherPlayer.receivesOfferToJoinRound()
			otherPlayer.joinsRound()

			await oldPlayer.receivesOfferToJoinRound()
			oldPlayer.joinsRound()

			newPlayer = await setupFakeClient 'thePlayer'

			await playRound otherPlayer, oldPlayer

			await otherPlayer.receivesOfferToJoinRound 2
			otherPlayer.joinsRound()
			await newPlayer.receivesOfferToJoinRound 2
			newPlayer.joinsRound()

			await playRound otherPlayer, newPlayer

			await newPlayer.receivesScores theOtherPlayer: 0, thePlayer: 2

	describe 'with two registered players', ->

		client1 = client2 = null
		eachPlayer = null

		beforeEach ->
			serverAlwaysOrdersPlayersAlphabeticallyInNewRounds()
			client1 = await setupFakeClient 'client1'
			client2 = await setupFakeClient 'client2'
			eachPlayer = new MultipleClients [client1, client2]
			game.start()

		afterEach ->
			eachPlayer.shutDown() if eachPlayer?

		it 'should host a round with a player calling and losing', =>
			await eachPlayer.receivesOfferToJoinRound()
			eachPlayer.joinsRound()
			await eachPlayer.receivesNotificationThatRoundIsStarting 1, 'client1', 'client2'
			
			await client1.isAskedToPlayATurn()
			serverRolls 6, 6
			client1.rolls()
			await eachPlayer.receivesNotificationThatPlayerRolls 'client1'
			await client1.receivesRolledDice dice.create(6, 6)
			client1.announcesDice dice.create(6, 6)

			await eachPlayer.receivesDiceAnnouncement 'client1', dice.create(6, 6)

			await client2.isAskedToPlayATurn()
			client2.wantsToSee()

			await eachPlayer.receivesNotificationThatPlayerWantsToSee 'client2'
			await eachPlayer.receivesActualDice dice.create(6, 6)
			await eachPlayer.receivesNotificationThatPlayerLost 'client2', 'SEE_FAILED'
			await eachPlayer.receivesScores client1: 1, client2: 0

		it 'should host a round with a player calling and winning', ->
			await eachPlayer.receivesOfferToJoinRound()
			eachPlayer.joinsRound()
			await eachPlayer.receivesNotificationThatRoundIsStarting 1, 'client1', 'client2'
			
			await client1.isAskedToPlayATurn()
			client1.rolls()
			serverRolls 4, 4
			await client1.receivesRolledDice dice.create(4, 4)
			client1.announcesDice dice.create(6, 6)

			await eachPlayer.receivesDiceAnnouncement 'client1', dice.create(6, 6)

			await client2.isAskedToPlayATurn()
			client2.wantsToSee()

			await eachPlayer.receivesActualDice dice.create(4, 4)
			await eachPlayer.receivesNotificationThatPlayerLost 'client1', 'CAUGHT_BLUFFING'
			await eachPlayer.receivesScores client1: 0, client2: 1

		player1LosesRound = ->
			await eachPlayer.receivesOfferToJoinRound()
			eachPlayer.joinsRound()
			await client1.isAskedToPlayATurn()
			client1.wantsToSee()
			await eachPlayer.receivesNotificationThatPlayerLost 'client1', 'SEE_BEFORE_FIRST_ROLL'

		it 'should keep score across multiple rounds', ->
			await player1LosesRound()
			await eachPlayer.receivesScores client1: 0, client2: 1

			await player1LosesRound()
			await eachPlayer.receivesScores client1: 0, client2: 2

	describe 'mia rules', ->

		client1 = client2 = client3 = null
		eachPlayer = null

		beforeEach ->
			serverAlwaysOrdersPlayersAlphabeticallyInNewRounds()
			client1 = await setupFakeClient 'client1'
			client2 = await setupFakeClient 'client2'
			client3 = await setupFakeClient 'client3'
			eachPlayer = new MultipleClients [client1, client2, client3]
			game.start()

		afterEach ->
			eachPlayer.shutDown()

		it 'when mia is announced, all other players immediately lose', ->
			serverRolls 2, 1
			await eachPlayer.receivesOfferToJoinRound()
			eachPlayer.joinsRound()
			
			await client1.isAskedToPlayATurn()
			client1.rolls()
			await client1.receivesRolledDice dice.create(2, 1)
			client1.announcesDice dice.create(2, 1)

			await eachPlayer.receivesDiceAnnouncement 'client1', dice.create(2, 1)
			await eachPlayer.receivesActualDice dice.create(2, 1)
			await eachPlayer.receivesNotificationThatPlayersLost ['client2', 'client3'], 'MIA'
			await eachPlayer.receivesScores client1: 1, client2: 0, client3: 0

		it 'when mia is announced wrongly, player immediately loses', ->
			serverRolls 3, 1
			await eachPlayer.receivesOfferToJoinRound()
			eachPlayer.joinsRound()

			await client1.isAskedToPlayATurn()
			client1.rolls()
			await client1.receivesRolledDice dice.create(3, 1)
			client1.announcesDice dice.create(2, 1)

			await eachPlayer.receivesDiceAnnouncement 'client1', dice.create(2, 1)
			await eachPlayer.receivesActualDice dice.create(3, 1)
			await eachPlayer.receivesNotificationThatPlayerLost 'client1', 'LIED_ABOUT_MIA'
			await eachPlayer.receivesScores client1: 0, client2: 1, client3: 1

class MultipleClients
	constructor: (clients) ->
		delegate = (methodName) =>
			(args...) =>
				for client in clients
					client[methodName](args...)
		delegateAsync = (methodName) =>
			(args...) =>
				promises = for client in clients
					client[methodName](args...)
				Promise.all(promises)

		for method in ['joinsRound', 'shutDown']
			@[method] = delegate method
		for method in ['receivesOfferToJoinRound', 'receivesDiceAnnouncement', 'receivesActualDice', 
				'receivesNotificationThatPlayerLost', 'receivesNotificationThatPlayersLost', 'receivesScores',
				'receivesNotificationThatRoundIsStarting', 'receivesNotificationThatPlayerRolls',
				'receivesNotificationThatPlayerWantsToSee' ] 
			@[method] = delegateAsync method

class BaseFakeClient
	constructor: (@name) ->
		@name = 'client' unless @name?
		@messages = []
		@currentToken = 'noTokenReceived'

	log: ->

	enableLogging: -> @log = console.log

	sendPlayerRegistration: ->
		@send "REGISTER;#{@name}"
	
	sendSpectatorRegistration: ->
		@send "REGISTER_SPECTATOR;#{@name}"

	receivesRegistrationConfirmation: ->
		@receives 'REGISTERED'

	receivesOfferToJoinRound: ->
		@receivesWithAppendedToken "ROUND STARTING"
	
	didNotReceiveOfferToJoinRound: ->
		matcher = (message) -> /ROUND STARTING/.test(message)
		expect(@hasReceivedMessageMatching matcher).toBeFalsy()
	
	joinsRound: ->
		@joinsRoundWithToken @currentToken

	joinsRoundWithToken: (token) ->
		@send "JOIN;#{token}"

	receivesNotificationThatRoundWasCanceled: (reason) ->
		@receives "ROUND CANCELED;#{reason}"

	receivesNotificationThatRoundIsStarting: (roundNumber, playernames...) ->
		@receives "ROUND STARTED;#{roundNumber};#{playernames.join()}"

	isAskedToPlayATurn: ->
		@receivesWithAppendedToken 'YOUR TURN'

	rolls: ->
		@send "ROLL;#{@currentToken}"

	wantsToSee: ->
		@send "SEE;#{@currentToken}"

	receivesRolledDice: (dice) ->
		@receivesWithAppendedToken "ROLLED;#{dice.die1},#{dice.die2}"
	
	announcesDice: (dice) ->
		@send "ANNOUNCE;#{dice};#{@currentToken}"

	receivesDiceAnnouncement: (playerName, dice) ->
		@receives "ANNOUNCED;#{playerName};#{dice}"

	receivesActualDice: (dice) ->
		@receives "ACTUAL DICE;#{dice}"
	
	receivesNotificationThatPlayerRolls: (player) ->
		@receives "PLAYER ROLLS;#{player}"
	
	receivesNotificationThatPlayerWantsToSee: (player) ->
		@receives "PLAYER WANTS TO SEE;#{player}"

	receivesNotificationThatPlayersLost: (players, reason) ->
		@receivesNotificationThatPlayerLost players.join(), reason

	receivesNotificationThatPlayerLost: (playerName, reason) ->
		@receives "PLAYER LOST;#{playerName};#{reason}"

	receivesScores: (scores) ->
		scoresString = ("#{name}:#{score}" for name, score of scores).join()
		@receives "SCORE;#{scoresString}"

	receivesWithAppendedToken: (expectedMessage) ->
		regex = new RegExp "#{expectedMessage};([^;]*)", 'g'
		matcher = (message) =>
			if match = regex.exec message
				@currentToken = match[1]
			match?
		@receivesMessageMatching expectedMessage, matcher

	receives: (expectedMessage) ->
		matcher = (message) -> expectedMessage == message
		@receivesMessageMatching expectedMessage, matcher

	receivesMessageMatching: (messageForDisplay, matcher) ->
		@log "[#{@name}] waiting for #{messageForDisplay}"
		waitFor 250, => @hasReceivedMessageMatching matcher

	hasReceivedMessageMatching: (matcher) ->
		for i in [0..@messages.length]
			message = @messages[i]
			if matcher(message)
				@messages = @messages[i+1..]
				return true
		return false

class FakeUdpClient extends BaseFakeClient
	constructor: (@serverPort, name) ->
		super name
		@socket = dgram.createSocket 'udp4', (msg) =>
			@log "[#{@name}] received #{msg.toString()}"
			@messages.push msg.toString()
		@socket.bind()

	send: (string) ->
		@log "[#{@name}] sending #{string}"
		buffer = new Buffer(string)
		@socket.send buffer, 0, buffer.length, @serverPort, 'localhost'

	shutDown: () ->
		@socket.close()


class FakeDiceRoller
	constructor: (@dice) ->
	roll: -> @dice

