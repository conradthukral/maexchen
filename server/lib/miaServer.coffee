dgram = require 'dgram'
miaGame = require './miaGame'

class RemotePlayer
	constructor: (@socket, @host, @port, @tokenGenerator) ->
		@sendMessage 'REGISTERED;0'

	willJoinRound: ->
		@sendMessage "ROUND STARTING;#{@tokenGenerator.generate()}"

	roundCanceled: (reason) ->
		@sendMessage "ROUND CANCELED;#{reason}"

	sendMessage: (message) ->
		console.log "sending #{message} to #{@host}:#{@port}"
		buffer = new Buffer(message)
		@socket.send buffer, 0, buffer.length, @port, @host

class Server
	constructor: (port, @timeout) ->
		self = this
		@game = miaGame.createGame()
		@game.setBroadcastTimeout @timeout
		@socket = dgram.createSocket 'udp4', (message, rinfo) ->
			fromHost = rinfo.address
			fromPort = rinfo.port
			self.handleMessage message.toString(), fromHost, fromPort
		@socket.bind port
		console.log "\nMia server started on port #{port}"

	handleMessage: (message, fromHost, fromPort) ->
		console.log "received #{message} from #{fromHost}:#{fromPort}"
		@game.registerPlayer new RemotePlayer @socket, fromHost, fromPort, @tokenGenerator
		@game.newRound() # TODO das ist hier keine Gute Idee

	shutDown: ->
		@socket.close()
		@game.stop()

	setTokenGenerator: (@tokenGenerator) ->

exports.start = (port, timeout) ->
	return new Server port, timeout
