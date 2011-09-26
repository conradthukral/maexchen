dgram = require 'dgram'
miaServer = require '../lib/miaServer'
dice = require '../lib/dice'

timeoutForClientAnswers = 100
serverPort = 9000
server = null

describe 'the Mia server', ->

	beforeEach ->
		server = miaServer.start serverPort, timeoutForClientAnswers

	afterEach ->
		server.shutDown()

	describe 'player setup', ->

		client = null

		beforeEach ->
			client = new FakeClient serverPort
			server.startGame()

		afterEach ->
			client.shutDown()

		it 'should accept player registrations', ->
			client.sendPlayerRegistration()
			client.receivesRegistrationConfirmation()

		it 'should keep trying to start a round while nobody joins', ->
			client.sendPlayerRegistration()

			client.receivesOfferToJoinRound()
			client.waitsUntilTimeout()

			client.receivesNotificationThatNobodyWantedToJoin()
			client.receivesOfferToJoinRound()
	
		it 'should silently ignore a player who tries to join with the wrong token', ->
			client.sendPlayerRegistration()

			client.receivesOfferToJoinRound()
			client.joinsRoundWithToken 'wrongToken'

			client.waitsUntilTimeout()
			client.receivesNotificationThatNobodyWantedToJoin()

		it 'should start a round when a player joins', ->
			client.sendPlayerRegistration()

			client.receivesOfferToJoinRound()
			client.joinsRound()

			client.receivesNotificationThatRoundIsStarting()

	describe 'with (hopefully soon two) registered players', ->

		client1 = null
		client2 = null

		setupFakeClient = (clientName) ->
			result = new FakeClient serverPort, clientName
			result.sendPlayerRegistration()
			result.receivesRegistrationConfirmation()
			result

		keepServerFromPermutingThePlayers = ->
			server.game.permuteCurrentRound = ->

		beforeEach ->
			keepServerFromPermutingThePlayers()
			server.setDiceRoller new FakeDiceRoller dice.create(2, 1)
			client1 = setupFakeClient 'client1'
			client2 = setupFakeClient 'client2'
			runs -> server.startGame()

		afterEach ->
			client1.shutDown()
			client2.shutDown()

		it 'should play a round when (hopefully soon) both players join', =>
			client1.receivesOfferToJoinRound()
			client1.joinsRound()

			client2.receivesOfferToJoinRound()
			client2.joinsRound()

			client1.receivesNotificationThatRoundIsStarting()
			client2.receivesNotificationThatRoundIsStarting()
			
			client1.isAskedToPlayATurn()

			client1.rolls()
			client1.receivesRolledDice dice.create(2, 1)
			client1.announcesDice dice.create(2, 1)

			client1.receivesDiceAnnouncement 'client1', dice.create(2, 1)
			client2.receivesDiceAnnouncement 'client1', dice.create(2, 1)

class FakeClient
	constructor: (@serverPort, @name) ->
		@name = 'client' unless @name?
		@messages = messages = []
		@socket = dgram.createSocket 'udp4', (msg) =>
			# console.log "[#{@name}] received #{msg.toString()}"
			messages.push msg.toString()
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

	receivesNotificationThatRoundIsStarting: ->
		@receives 'ROUND STARTED;testClient:0' #FIXME this is wrong now

	isAskedToPlayATurn: ->
		@receivesWithAppendedToken 'YOUR TURN'

	rolls: ->
		runs =>
			@send "ROLL;#{@currentToken}"

	receivesRolledDice: (dice) ->
		@receivesWithAppendedToken "ROLLED;#{dice.die1},#{dice.die2}"
	
	announcesDice: (dice) ->
		runs =>
			@send "ANNOUNCE;#{dice};#{@currentToken}"

	receivesDiceAnnouncement: (playerName, dice) ->
		@receives "ANNOUNCED;#{playerName};#{dice}"

	waitsUntilTimeout: ->
		waits timeoutForClientAnswers

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
		for message in @messages
			return true if matcher(message)
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

