dgram = require 'dgram'
miaGame = require './miaGame'

String::startsWith = (prefix) ->
	@substring(0, prefix.length) == prefix

class RemotePlayer
	constructor: (@socket, @host, @port, @tokenGenerator) ->
		@sendMessage 'REGISTERED;0'

	willJoinRound: (@joinCallback) ->
		@currentToken = @tokenGenerator.generate()
		@sendMessage "ROUND STARTING;#{@currentToken}"

	yourTurn: (@playerTurnCallback) ->
		@currentToken = @tokenGenerator.generate()
		@sendMessage "YOUR TURN;#{@currentToken}"

	yourRoll: (dice, announce) ->
		@currentToken = @tokenGenerator.generate()
		@sendMessage "ROLLED;#{dice};#{@currentToken}"

	roundCanceled: (reason) ->
		@sendMessage "ROUND CANCELED;#{reason}"

	roundStarted: ->
		@sendMessage "ROUND STARTED;testClient:0" #TODO correct players/scores

	announcedDiceBy: (dice, player) ->

	playerLost: (player) ->

	handleMessage: (messageCommand, messageArgs) ->
		switch messageCommand
			when 'JOIN'
				if messageArgs[0] == @currentToken
					@joinCallback true
			when 'ROLL'
				@playerTurnCallback miaGame.Messages.ROLL

	sendMessage: (message) ->
		console.log "sending '#{message}' to #{@host}:#{@port}"
		buffer = new Buffer(message)
		@socket.send buffer, 0, buffer.length, @port, @host

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

	handleMessage: (messageCommand, messageArgs, fromHost, fromPort) ->
		if messageCommand == 'REGISTER'
			newPlayer = new RemotePlayer @socket, fromHost, fromPort, @tokenGenerator
			@addPlayer fromHost, fromPort, newPlayer
			@game.registerPlayer newPlayer
			@game.newRound() # TODO das ist hier keine Gute Idee
		else
			@playerFor(fromHost, fromPort).handleMessage messageCommand, messageArgs
	
	shutDown: ->
		@socket.close()
		@game.stop()

	setTokenGenerator: (@tokenGenerator) ->

	setDiceRoller: (diceRoller) ->
		@game.setDiceRoller diceRoller
	
	playerFor: (host, port) ->
		@players["#{host}:#{port}"]
	
	addPlayer: (host, port, player) ->
		@players["#{host}:#{port}"] = player
	
exports.start = (port, timeout) ->
	return new Server port, timeout
