dgram = require 'dgram'
miaServer = require '../lib/miaServer'

serverPort = 9000
server = null
client = null

describe 'the Mia server', ->

	beforeEach ->
		server = miaServer.start serverPort
		client = new FakeClient serverPort

	afterEach ->
		server.shutDown()
		client.shutDown()

	it 'should accept registrations', ->
		client.sendPlayerRegistration()

		client.receivesRegistrationConfirmation()


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
