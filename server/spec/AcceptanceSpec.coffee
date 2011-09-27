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

describe 'the Mia server', ->

	beforeEach ->
		server = miaServer.start serverPort, timeoutForClientAnswers

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
			client.receivesNotificationThatNobodyWantedToJoin()
			
			client.receivesOfferToJoinRound()
	
	describe 'with two registered players', ->

		client1 = null
		client2 = null

		keepServerFromPermutingThePlayers = ->
			server.game.permuteCurrentRound = ->

		beforeEach ->
			keepServerFromPermutingThePlayers()
			server.setDiceRoller new FakeDiceRoller dice.create(6, 6)
			client1 = setupFakeClient 'client1'
			client2 = setupFakeClient 'client2'
			runs -> server.startGame()

		afterEach ->
			client1.shutDown()
			client2.shutDown()

		it 'should play a round', =>
			client1.receivesOfferToJoinRound()
			client1.joinsRound()

			client2.receivesOfferToJoinRound()
			client2.joinsRound()

			client1.receivesNotificationThatRoundIsStarting 'client1', 'client2'
			client2.receivesNotificationThatRoundIsStarting 'client1', 'client2'
			
			client1.isAskedToPlayATurn()
			client1.rolls()
			client1.receivesRolledDice dice.create(6, 6)
			client1.announcesDice dice.create(6, 6)

			client1.receivesDiceAnnouncement 'client1', dice.create(6, 6)
			client2.receivesDiceAnnouncement 'client1', dice.create(6, 6)

			client2.isAskedToPlayATurn()
			client2.wantsToSee()

			client1.receivesActualDice dice.create(6, 6)
			client2.receivesActualDice dice.create(6, 6)
			client1.receivesNotificationThatPlayerLost 'client2', 'saw that the announcement was true'
			client2.receivesNotificationThatPlayerLost 'client2', 'saw that the announcement was true'

			client1.receivesScores client1: 1, client2: 0
			client2.receivesScores client1: 1, client2: 0

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
		@send "REGISTER;#{@name};testPwd"

	receivesRegistrationConfirmation: ->
		@receives 'REGISTERED;0'

	receivesOfferToJoinRound: ->
		@receivesWithAppendedToken 'ROUND STARTING'
	
	joinsRound: ->
		runs =>
			@joinsRoundWithToken @currentToken

	joinsRoundWithToken: (token) ->
		@send "JOIN;#{token}"

	receivesNotificationThatNobodyWantedToJoin: ->
		@receives 'ROUND CANCELED;no players'

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

