dgram = require 'dgram'
miaServer = require '../lib/miaServer'

serverPort = 9000
server = null
client = null

describe 'the Mia server', ->

	beforeEach ->
		server = miaServer.start serverPort
		server.setTokenGenerator new FakeTokenGenerator
		client = new FakeClient serverPort

	afterEach ->
		server.shutDown()
		client.shutDown()

	it 'should start a game when the first player connects', ->
		client.sendPlayerRegistration()

		client.receivesRegistrationConfirmation()
		client.receivesOfferToJoinRoundWithToken 'token1'

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

