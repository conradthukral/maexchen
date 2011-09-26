uuid = require 'node-uuid'

miaGame = require './miaGame'
dice = require './dice'


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


exports.create = (name, socket, host, port) ->
	new RemotePlayer(name, socket, host, port)

