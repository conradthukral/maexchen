dgram = require 'dgram'

miaGame = require './miaGame'
remotePlayer = require './remotePlayer'

class UdpConnection
	constructor: (@host, @port) ->
		@id = "#{@host}:#{@port}"

class Server
	constructor: (port, @timeout) ->
		handleRawMessage = (message, rinfo) =>
			fromHost = rinfo.address
			fromPort = rinfo.port
			console.log "received '#{message}' from #{fromHost}:#{fromPort}" if @logging
			messageParts = message.toString().split ';'
			command = messageParts[0]
			args = messageParts[1..]
			@handleMessage command, args, new UdpConnection(fromHost, fromPort)

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

	handleMessage: (messageCommand, messageArgs, connection) ->
		console.log "handleMessage '#{messageCommand}' '#{messageArgs}' from #{connection.id}" if @logging
		if messageCommand == 'REGISTER'
			name = messageArgs[0]
			@handleRegistration name, connection, false
		else if messageCommand == 'REGISTER_SPECTATOR'
			name = messageArgs[0]
			@handleRegistration name, connection, true
		else
			player = @playerFor connection
			player?.handleMessage messageCommand, messageArgs
	
	handleRegistration: (name, connection, isSpectator) ->
		newPlayer = @createPlayer name, connection
		unless @isValidName name
			newPlayer.registrationRejected 'INVALID_NAME'
		else if @nameIsTakenByAnotherPlayer name, connection
			newPlayer.registrationRejected 'NAME_ALREADY_TAKEN'
		else
			@addPlayer connection, newPlayer, isSpectator

	isValidName: (name) ->
		name != '' and name.length <= 20 and not /[,;:\s]/.test name

	nameIsTakenByAnotherPlayer: (name, connection) ->
		existingPlayer = @findPlayerByName(name)
		existingPlayer and existingPlayer.remoteHost != connection.host

	findPlayerByName: (name) ->
		for key, player of @players
			return player if player.name == name
		null

	shutDown: ->
		@socket.close()
		@game.stop()

	setDiceRoller: (diceRoller) ->
		@game.setDiceRoller diceRoller
	
	playerFor: (connection) ->
		@players[connection.id]
	
	addPlayer: (connection, player, isSpectator) ->
		@players[connection.id] = player
		if isSpectator
			@game.registerSpectator player
		else
			@game.registerPlayer player
		player.registered()

	createPlayer: (name, connection) ->
		sendMessageCallback = (message) =>
			console.log "sending '#{message}' to #{name} (#{connection.id})" if @logging
			buffer = new Buffer(message)
			@socket.send buffer, 0, buffer.length, connection.port, connection.host
		result = remotePlayer.create name, sendMessageCallback
		result.remoteHost = connection.host
		result

exports.start = (port, timeout) ->
	return new Server port, timeout
