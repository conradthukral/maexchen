dgram = require 'dgram'
miaGame = require './miaGame'

String::startsWith = (prefix) ->
	@substring(0, prefix.length) == prefix

class RemotePlayer
	constructor: (@socket, @host, @port, @tokenGenerator) ->
		@sendMessage 'REGISTERED;0'

	willJoinRound: (@joinCallback) ->
		@sendMessage "ROUND STARTING;#{@tokenGenerator.generate()}"

	roundCanceled: (reason) ->
		@sendMessage "ROUND CANCELED;#{reason}"

	roundStarted: ->
		@sendMessage "ROUND STARTED;testClient:0" #TODO correct players/scores

	handleMessage: (message) ->
		@joinCallback true #TODO check token

	sendMessage: (message) ->
		console.log "sending '#{message}' to #{@host}:#{@port}"
		buffer = new Buffer(message)
		@socket.send buffer, 0, buffer.length, @port, @host

class Server
	constructor: (port, @timeout) ->
		handleRawMessage = (message, rinfo) =>
			fromHost = rinfo.address
			fromPort = rinfo.port
			@handleMessage message.toString(), fromHost, fromPort

		@players = {}
		@game = miaGame.createGame()
		@game.setBroadcastTimeout @timeout
		@socket = dgram.createSocket 'udp4', handleRawMessage
		@socket.bind port
		console.log "\nMia server started on port #{port}"

	handleMessage: (message, fromHost, fromPort) ->
		console.log "received '#{message}' from #{fromHost}:#{fromPort}"
		if message.startsWith 'REGISTER;'
			newPlayer = new RemotePlayer @socket, fromHost, fromPort, @tokenGenerator
			@addPlayer fromHost, fromPort, newPlayer
			@game.registerPlayer newPlayer
			@game.newRound() # TODO das ist hier keine Gute Idee
		else
			@playerFor(fromHost, fromPort).handleMessage message
	
	shutDown: ->
		@socket.close()
		@game.stop()

	setTokenGenerator: (@tokenGenerator) ->

	playerFor: (host, port) ->
		@players["#{host}:#{port}"]
	
	addPlayer: (host, port, player) ->
		@players["#{host}:#{port}"] = player
	
exports.start = (port, timeout) ->
	return new Server port, timeout
