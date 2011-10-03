dgram = require 'dgram'

miaGame = require './miaGame'
remotePlayer = require './remotePlayer'

class Server
	constructor: (port, @timeout) ->
		handleRawMessage = (message, rinfo) =>
			fromHost = rinfo.address
			fromPort = rinfo.port
			console.log "received '#{message}' from #{fromHost}:#{fromPort}" if @logging
			messageParts = message.toString().split ';'
			command = messageParts[0]
			args = messageParts[1..]
			@handleMessage command, args, fromHost, fromPort

		@logging = false
		@players = {}
		@game = miaGame.createGame()
		@game.setBroadcastTimeout @timeout
		@socket = dgram.createSocket 'udp4', handleRawMessage
		@socket.bind port

	enableLogging: -> @logging = true

	startGame: ->
		@game.newRound()
	
	doNotStartRoundsEarly: ->
		@game.doNotStartRoundsEarly()

	handleMessage: (messageCommand, messageArgs, fromHost, fromPort) ->
		if messageCommand == 'REGISTER'
			name = messageArgs[0]
			@handleRegistration name, fromHost, fromPort, false
		else if messageCommand == 'REGISTER_SPECTATOR'
			name = messageArgs[0]
			@handleRegistration name, fromHost, fromPort, true
		else
			player = @playerFor(fromHost, fromPort)
			player?.handleMessage messageCommand, messageArgs
	
	handleRegistration: (name, fromHost, fromPort, isSpectator) ->
		newPlayer = @createPlayer name, fromHost, fromPort
		unless @isValidName name
			newPlayer.registrationRejected 'INVALID_NAME'
		else if @nameIsTakenByAnotherPlayer name, fromHost
			newPlayer.registrationRejected 'NAME_ALREADY_TAKEN'
		else
			@addPlayer fromHost, fromPort, newPlayer, isSpectator

	isValidName: (name) ->
		name != '' and name.length <= 20 and not /[,;:\s]/.test name

	nameIsTakenByAnotherPlayer: (name, newHost) ->
		existingPlayer = @findPlayerByName(name)
		existingPlayer and existingPlayer.remoteHost != newHost

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
	
	addPlayer: (host, port, player, isSpectator) ->
		@players["#{host}:#{port}"] = player
		if isSpectator
			@game.registerSpectator player
		else
			@game.registerPlayer player
		player.registered()

	createPlayer: (name, host, port) ->
		sendMessageCallback = (message) =>
			console.log "sending '#{message}' to #{name} (#{host}:#{port})" if @logging
			buffer = new Buffer(message)
			@socket.send buffer, 0, buffer.length, port, host
		result = remotePlayer.create name, sendMessageCallback
		result.remoteHost = host
		result
	
exports.start = (port, timeout) ->
	return new Server port, timeout
