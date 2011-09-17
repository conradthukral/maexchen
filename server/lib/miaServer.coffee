dgram = require 'dgram'

class Server
	constructor: (port) ->
		self = this
		@socket = dgram.createSocket 'udp4', (message, rinfo) ->
			fromHost = rinfo.address
			fromPort = rinfo.port
			self.handleMessage message.toString(), fromHost, fromPort
		@socket.bind port
		console.log "\nMia server started on port #{port}"

	handleMessage: (message, fromHost, fromPort) ->
		console.log "received #{message} from #{fromHost}:#{fromPort}"
		@sendMessage 'REGISTERED;0', fromHost, fromPort

	sendMessage: (message, host, port) ->
		console.log "sending #{message} to #{host}:#{port}"
		buffer = new Buffer message
		@socket.send buffer, 0, buffer.length, port, host

	shutDown: ->
		@socket.close()

exports.start = (port) ->
	return new Server port
