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
			@handleRegistration name, fromHost, fromPort
		else
			@playerFor(fromHost, fromPort).handleMessage messageCommand, messageArgs
	
	handleRegistration: (name, fromHost, fromPort) ->
		newPlayer = @createPlayer name, fromHost, fromPort
		existingPlayer = @findPlayerByName(name)
		if not existingPlayer or existingPlayer.remoteHost == fromHost
			@addPlayer fromHost, fromPort, newPlayer
		else
			newPlayer.registrationRejected()

	findPlayerByName: (name) ->
		for key, player of @players
			return player if player.name == name
		null

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
		player.registered()

	createPlayer: (name, host, port) ->
		sendMessageCallback = (message) =>
			console.log "sending '#{message}' to #{name} (#{host}:#{port})"
			buffer = new Buffer(message)
			@socket.send buffer, 0, buffer.length, port, host
		result = remotePlayer.create name, sendMessageCallback
		result.remoteHost = host
		result
	
exports.start = (port, timeout) ->
	return new Server port, timeout
