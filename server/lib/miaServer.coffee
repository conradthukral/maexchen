dgram = require 'dgram'
miaGame = require './miaGame'

class RemotePlayer
	constructor: (@socket, @host, @port) ->
		@sendMessage 'REGISTERED;0'

	willJoinRound: ->
		console.log 'will join round?'
		@sendMessage 'ROUND STARTING;token1'


	sendMessage: (message) ->
		console.log "sending #{message} to #{@host}:#{@port}"
		buffer = new Buffer(message)
		@socket.send buffer, 0, buffer.length, @port, @host

class Server
	constructor: (port) ->
		self = this
		@game = miaGame.createGame()
		@socket = dgram.createSocket 'udp4', (message, rinfo) ->
			fromHost = rinfo.address
			fromPort = rinfo.port
			self.handleMessage message.toString(), fromHost, fromPort
		@socket.bind port
		console.log "\nMia server started on port #{port}"

	handleMessage: (message, fromHost, fromPort) ->
		console.log "received #{message} from #{fromHost}:#{fromPort}"
		@game.registerPlayer new RemotePlayer @socket, fromHost, fromPort
		@game.newRound() # TODO das ist hier keine Gute Idee

	shutDown: ->
		@socket.close()
		@game.stop()

	setTokenGenerator: ->

exports.start = (port) ->
	return new Server port
