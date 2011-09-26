dgram = require 'dgram'
uuid = require 'node-uuid'

miaGame = require './miaGame'
dice = require './dice'

String::startsWith = (prefix) ->
	@substring(0, prefix.length) == prefix

generateToken = -> uuid()

class InactiveState
	handleMessage: (messageCommand, messageArgs) ->

class WaitingForJoinState
	constructor: (@expectedToken, @joinCallback) ->
	handleMessage: (messageCommand, messageArgs) ->
		actualToken = messageArgs[0]
		if messageCommand == 'JOIN' and actualToken == @expectedToken
			@joinCallback true
		new InactiveState

class WaitingForTurnState
	constructor: (@token, @callback) ->
	handleMessage: (command, args) ->
		if command == 'ROLL' # TODO token prüfen
			@callback miaGame.Messages.ROLL
		new InactiveState

class WaitingForAnnounceState
	constructor: (@token, @callback) ->
	handleMessage: (command, args) ->
		if command == 'ANNOUNCE' # TODO token prüfen
			announcedDice = dice.parse args[0]
			@callback announcedDice
		new InactiveState

class RemotePlayer
	constructor: (@name, @socket, @host, @port) ->
		@sendMessage 'REGISTERED;0'
		@currentState = new InactiveState

	willJoinRound: (callback) ->
		token = generateToken()
		@currentState = new WaitingForJoinState(token, callback)
		@sendMessage "ROUND STARTING;#{token}"

	yourTurn: (callback) ->
		token = generateToken()
		@currentState = new WaitingForTurnState(token, callback)
		@sendMessage "YOUR TURN;#{token}"

	yourRoll: (dice, callback) ->
		token = generateToken()
		@currentState = new WaitingForAnnounceState(token, callback)
		@sendMessage "ROLLED;#{dice};#{token}"

	roundCanceled: (reason) ->
		@sendMessage "ROUND CANCELED;#{reason}"

	roundStarted: ->
		@sendMessage "ROUND STARTED;testClient:0" #TODO correct players/scores

	announcedDiceBy: (dice, player) ->
		@sendMessage "ANNOUNCED;#{player.name};#{dice}"

	playerLost: (player) ->

	handleMessage: (messageCommand, messageArgs) ->
		@currentState = @currentState.handleMessage messageCommand, messageArgs

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

	startGame: ->
		@game.newRound()

	handleMessage: (messageCommand, messageArgs, fromHost, fromPort) ->
		if messageCommand == 'REGISTER'
			name = messageArgs[0]
			newPlayer = new RemotePlayer name, @socket, fromHost, fromPort
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
	
exports.start = (port, timeout) ->
	return new Server port, timeout
