dgram = require 'dgram'

miaGame = require './miaGame'
remotePlayer = require './remotePlayer'

class Server
	constructor: (port, @timeout) ->
		handleRawMessage = (message, rinfo) =>
			fromHost = rinfo.address
			fromPort = rinfo.port
			console.log "received '#{message}' from #{fromHost}:#{fromPort}"
			messageParts = message.toString().split ';'
			command = messageParts[0]
			args = messageParts[1..]
			@handleMessage command, args, fromHost, fromPort

		@players = {}
		@game = miaGame.createGame()
		@game.setBroadcastTimeout @timeout
		@socket = dgram.createSocket 'udp4', handleRawMessage
		@socket.bind port
		console.log "\nMia server started on port #{port}"

	startGame: ->
		@game.newRound()

	handleMessage: (messageCommand, messageArgs, fromHost, fromPort) ->
		if messageCommand == 'REGISTER'
			name = messageArgs[0]
			newPlayer = @createPlayer name, fromHost, fromPort
			@addPlayer fromHost, fromPort, newPlayer
		else
			@playerFor(fromHost, fromPort).handleMessage messageCommand, messageArgs
	
	shutDown: ->
		@socket.close()
		@game.stop()

	setDiceRoller: (diceRoller) ->
		@game.setDiceRoller diceRoller
	
	playerFor: (host, port) ->
		@players["#{host}:#{port}"]
	
	addPlayer: (host, port, player) ->
		@players["#{host}:#{port}"] = player
		@game.registerPlayer player
	
	createPlayer: (name, host, port) ->
		sendMessageCallback = (message) =>
			console.log "sending '#{message}' to #{host}:#{port}"
			buffer = new Buffer(message)
			@socket.send buffer, 0, buffer.length, port, host
		remotePlayer.create name, sendMessageCallback
		
	
exports.start = (port, timeout) ->
	return new Server port, timeout
