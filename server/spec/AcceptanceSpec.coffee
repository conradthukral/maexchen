dgram = require 'dgram'
miaServer = require '../lib/miaServer'

timeoutForClientAnswers = 100
serverPort = 9000
server = null
client = null

describe 'the Mia server', ->

	beforeEach ->
		server = miaServer.start serverPort, timeoutForClientAnswers
		server.setTokenGenerator new FakeTokenGenerator
		client = new FakeClient serverPort

	afterEach ->
		server.shutDown()
		client.shutDown()

	it 'should keep trying to start a round while nobody wants to play', ->
		client.sendPlayerRegistration()
		client.receivesRegistrationConfirmation()

		client.receivesOfferToJoinRoundWithToken 'token1'

		client.waitsUntilTimeout()

		client.receivesNotificationThatNobodyWantedToJoin()
		client.receivesOfferToJoinRoundWithToken 'token2'

class FakeClient
	constructor: (@serverPort) ->
		@messages = messages = []
		@socket = dgram.createSocket 'udp4', (msg) ->
			messages.push msg.toString()
		@socket.bind()
		@clientPort = @socket.address().port

	sendPlayerRegistration: ->
		@send "REGISTER;testClient;testPwd"

	receivesRegistrationConfirmation: ->
		@receives 'REGISTERED;0'

	receivesOfferToJoinRoundWithToken: (token) ->
		@receives "ROUND STARTING;#{token}"

	receivesNotificationThatNobodyWantedToJoin: ->
		@receives 'ROUND CANCELED;no players'

	waitsUntilTimeout: ->
		waits timeoutForClientAnswers

	receives: (expectedMessage) ->
		messageReceived = => @hasReceived expectedMessage
		waitsFor messageReceived, "message #{expectedMessage}", 250

	hasReceived: (expectedMessage) ->
		@messages.indexOf(expectedMessage) >= 0

	send: (string) ->
		buffer = new Buffer(string)
		@socket.send buffer, 0, buffer.length, @serverPort, 'localhost'

	shutDown: () ->
		@socket.close()

class FakeTokenGenerator
	constructor: ->
		@counter = 0

	generate: ->
		"token#{++@counter}"

