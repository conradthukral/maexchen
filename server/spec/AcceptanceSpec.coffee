dgram = require 'dgram'
miaServer = require '../lib/miaServer'
dice = require '../lib/dice'

timeoutForClientAnswers = 100
serverPort = 9000
server = null

setupFakeClient = (clientName) ->
	result = new FakeClient serverPort, clientName
	result.sendPlayerRegistration()
	result.receivesRegistrationConfirmation()
	result
		
keepServerFromPermutingThePlayers = ->
	server.game.permuteCurrentRound = ->

describe 'the Mia server', ->

	beforeEach ->
		server = miaServer.start serverPort, timeoutForClientAnswers
		server.rolls = (die1, die2) ->
			@setDiceRoller new FakeDiceRoller dice.create(die1, die2)

	afterEach ->
		server.shutDown()

	describe 'player setup', ->

		client = null

		beforeEach ->
			client = new FakeClient serverPort

		afterEach ->
			client.shutDown()

		it 'should accept player registrations', ->
			client.sendPlayerRegistration()
			client.receivesRegistrationConfirmation()

	describe 'round setup', ->

		client = null

		beforeEach ->
			client = setupFakeClient 'testClient'
			runs -> server.startGame()

		afterEach ->
			client.shutDown()

		it 'should keep trying to start a round while nobody joins', ->
			client.receivesOfferToJoinRound()
			client.receivesNotificationThatRoundWasCanceled 'no players'

			client.receivesOfferToJoinRound()
	
	describe 'when only one player participates in a round', ->

		player = null

		beforeEach ->
			player = setupFakeClient 'thePlayer'
			runs -> server.startGame()

		afterEach ->
			player.shutDown()

		it 'should award the player a point without playing the round', ->
			player.receivesOfferToJoinRound()
			player.joinsRound()
			player.receivesNotificationThatRoundIsStarting 'thePlayer'
			player.receivesNotificationThatRoundWasCanceled 'only one player'
			player.receivesScores thePlayer: 1
			
			player.receivesOfferToJoinRound()

	describe 'previously registered player registers again', ->

		oldPlayer = newPlayer = otherPlayer = null

		beforeEach ->
			oldPlayer = setupFakeClient 'thePlayer'
			otherPlayer = setupFakeClient 'theOtherPlayer'
			server.rolls 3, 1
			keepServerFromPermutingThePlayers()
			runs -> server.startGame()

		afterEach ->
			oldPlayer.shutDown()
			newPlayer.shutDown()
			otherPlayer.shutDown()

		playRound = (player1, player2) ->
			player1.isAskedToPlayATurn()
			player1.rolls()
			player1.receivesRolledDice dice.create(3, 1)
			player1.announcesDice dice.create(6, 6)
			player2.isAskedToPlayATurn()
			player2.wantsToSee()

		it 'should allow the new player to take the place of the old player in the next round, keeping the score', ->
			otherPlayer.receivesOfferToJoinRound()
			otherPlayer.joinsRound()

			oldPlayer.receivesOfferToJoinRound()
			oldPlayer.joinsRound()

			newPlayer = setupFakeClient 'thePlayer'

			playRound otherPlayer, oldPlayer

			otherPlayer.receivesOfferToJoinRound()
			otherPlayer.joinsRound()
			newPlayer.receivesOfferToJoinRound()
			newPlayer.joinsRound()

			playRound otherPlayer, newPlayer

			newPlayer.receivesScores theOtherPlayer: 0, thePlayer: 2

	describe 'with two registered players', ->

		client1 = client2 = null
		eachPlayer = null

		beforeEach ->
			keepServerFromPermutingThePlayers()
			client1 = setupFakeClient 'client1'
			client2 = setupFakeClient 'client2'
			eachPlayer = new MultipleClients [client1, client2]
			runs -> server.startGame()

		afterEach ->
			eachPlayer.shutDown()

		it 'should host a round with a player calling and losing', =>
			eachPlayer.receivesOfferToJoinRound()
			eachPlayer.joinsRound()
			eachPlayer.receivesNotificationThatRoundIsStarting 'client1', 'client2'
			
			client1.isAskedToPlayATurn()
			client1.rolls()
			server.rolls 6, 6
			client1.receivesRolledDice dice.create(6, 6)
			client1.announcesDice dice.create(6, 6)

			eachPlayer.receivesDiceAnnouncement 'client1', dice.create(6, 6)

			client2.isAskedToPlayATurn()
			client2.wantsToSee()

			eachPlayer.receivesActualDice dice.create(6, 6)
			eachPlayer.receivesNotificationThatPlayerLost 'client2', 'saw that the announcement was true'
			eachPlayer.receivesScores client1: 1, client2: 0

		it 'should host a round with a player calling and winning', ->
			eachPlayer.receivesOfferToJoinRound()
			eachPlayer.joinsRound()
			eachPlayer.receivesNotificationThatRoundIsStarting 'client1', 'client2'
			
			client1.isAskedToPlayATurn()
			client1.rolls()
			server.rolls 4, 4
			client1.receivesRolledDice dice.create(4, 4)
			client1.announcesDice dice.create(6, 6)

			eachPlayer.receivesDiceAnnouncement 'client1', dice.create(6, 6)

			client2.isAskedToPlayATurn()
			client2.wantsToSee()

			eachPlayer.receivesActualDice dice.create(4, 4)
			eachPlayer.receivesNotificationThatPlayerLost 'client1', 'was caught bluffing'
			eachPlayer.receivesScores client1: 0, client2: 1

		player1LosesARound = () ->
			eachPlayer.receivesOfferToJoinRound()
			eachPlayer.joinsRound()
			client1.isAskedToPlayATurn()
			client1.wantsToSee()
			eachPlayer.receivesNotificationThatPlayerLost 'client1', 'wanted to see dice before the first roll'

		it 'should keep score across multiple rounds', ->
			player1LosesARound()
			eachPlayer.receivesScores client1: 0, client2: 1

			player1LosesARound()
			eachPlayer.receivesScores client1: 0, client2: 2


	describe 'mia rules', ->

		client1 = client2 = client3 = null
		eachPlayer = null

		beforeEach ->
			keepServerFromPermutingThePlayers()
			client1 = setupFakeClient 'client1'
			client2 = setupFakeClient 'client2'
			client3 = setupFakeClient 'client3'
			eachPlayer = new MultipleClients [client1, client2, client3]
			runs -> server.startGame()

		afterEach ->
			eachPlayer.shutDown()

		it 'when mia is announced, all other players immediately lose', ->
			server.setDiceRoller new FakeDiceRoller dice.create(2, 1)
			eachPlayer.receivesOfferToJoinRound()
			eachPlayer.joinsRound()
			
			client1.isAskedToPlayATurn()
			client1.rolls()
			client1.receivesRolledDice dice.create(2, 1)
			client1.announcesDice dice.create(2, 1)

			eachPlayer.receivesDiceAnnouncement 'client1', dice.create(2, 1)
			eachPlayer.receivesActualDice dice.create(2, 1)
			eachPlayer.receivesNotificationThatPlayersLost ['client2', 'client3'], 'mia'
			eachPlayer.receivesScores client1: 1, client2: 0, client3: 0

		it 'when mia is announced wrongly, player immediately loses', ->
			server.setDiceRoller new FakeDiceRoller dice.create(3, 1)
			eachPlayer.receivesOfferToJoinRound()
			eachPlayer.joinsRound()
			
			client1.isAskedToPlayATurn()
			client1.rolls()
			client1.receivesRolledDice dice.create(3, 1)
			client1.announcesDice dice.create(2, 1)

			eachPlayer.receivesDiceAnnouncement 'client1', dice.create(2, 1)
			eachPlayer.receivesActualDice dice.create(3, 1)
			eachPlayer.receivesNotificationThatPlayerLost 'client1', 'wrongly announced mia'
			eachPlayer.receivesScores client1: 0, client2: 1, client3: 1

class MultipleClients
	constructor: (clients) ->
		wrapMethod = (methodName) =>
			(args...) =>
				for client in clients
					client[methodName](args...)

		exampleClient = clients[0]
		for method of exampleClient
			@[method] = wrapMethod method
			
class FakeClient
	constructor: (@serverPort, @name) ->
		@name = 'client' unless @name?
		@messages = []
		@socket = dgram.createSocket 'udp4', (msg) =>
			# console.log "[#{@name}] received #{msg.toString()}"
			@messages.push msg.toString()
		@socket.bind()
		@clientPort = @socket.address().port
		@currentToken = 'noTokenReceived'

	sendPlayerRegistration: ->
		@send "REGISTER;#{@name}"

	receivesRegistrationConfirmation: ->
		@receives 'REGISTERED'

	receivesOfferToJoinRound: ->
		@receivesWithAppendedToken 'ROUND STARTING'
	
	joinsRound: ->
		runs =>
			@joinsRoundWithToken @currentToken

	joinsRoundWithToken: (token) ->
		@send "JOIN;#{token}"

	receivesNotificationThatRoundWasCanceled: (reason) ->
		@receives "ROUND CANCELED;#{reason}"

	receivesNotificationThatRoundIsStarting: (playernames...) ->
		@receives "ROUND STARTED;#{playernames.join()}"

	isAskedToPlayATurn: ->
		@receivesWithAppendedToken 'YOUR TURN'

	rolls: ->
		runs =>
			@send "ROLL;#{@currentToken}"

	wantsToSee: ->
		runs =>
			@send "SEE;#{@currentToken}"

	receivesRolledDice: (dice) ->
		@receivesWithAppendedToken "ROLLED;#{dice.die1},#{dice.die2}"
	
	announcesDice: (dice) ->
		runs =>
			@send "ANNOUNCE;#{dice};#{@currentToken}"

	receivesDiceAnnouncement: (playerName, dice) ->
		@receives "ANNOUNCED;#{playerName};#{dice}"

	receivesActualDice: (dice) ->
		@receives "ACTUAL DICE;#{dice}"
	
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
		runs =>
			console.log "[#{@name}] waiting for #{messageForDisplay}"
			messageReceived = => @hasReceivedMessageMatching matcher
			waitsFor messageReceived, messageForDisplay, 250

	hasReceivedMessageMatching: (matcher) ->
		for i in [0..@messages.length]
			message = @messages[i]
			if matcher(message)
				@messages = @messages[i+1..]
				return true
		@messages = []
		return false

	send: (string) ->
		runs =>
			console.log "[#{@name}] sending #{string}"
			buffer = new Buffer(string)
			@socket.send buffer, 0, buffer.length, @serverPort, 'localhost'

	shutDown: () ->
		@socket.close()

class FakeDiceRoller
	constructor: (@dice) ->
	roll: -> @dice

