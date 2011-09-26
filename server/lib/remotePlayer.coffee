uuid = require 'node-uuid'

miaGame = require './miaGame'
dice = require './dice'

class InactiveState
	handleMessage: (messageCommand, messageArgs) ->
		this

class WaitingForJoinState
	constructor: (@expectedToken, @joinCallback) ->
	handleMessage: (messageCommand, messageArgs) ->
		actualToken = messageArgs[0]
		if messageCommand == 'JOIN' and actualToken == @expectedToken
			@joinCallback true
			new InactiveState
		else
			this

class WaitingForTurnState
	constructor: (@token, @callback) ->
	handleMessage: (command, args) ->
		token = args[0]
		if (token == @token)
			switch command
				when 'ROLL'
					@callback miaGame.Messages.ROLL
					return new InactiveState
				when 'SEE'
					@callback miaGame.Messages.SEE
					return new InactiveState
		this

class WaitingForAnnounceState
	constructor: (@token, @callback) ->
	handleMessage: (command, args) ->
		announcedDice = dice.parse args[0]
		token = args[1]
		if command == 'ANNOUNCE' and token == @token and announcedDice
			@callback announcedDice
			new InactiveState
		else
			this

class RemotePlayer
	constructor: (@name, @sendMessageCallback) ->
		@currentState = new InactiveState

	registered: ->
		@sendMessage 'REGISTERED;0'

	willJoinRound: (callback) ->
		token = @generateToken()
		@currentState = new WaitingForJoinState(token, callback)
		@sendMessage "ROUND STARTING;#{token}"

	yourTurn: (callback) ->
		token = @generateToken()
		@currentState = new WaitingForTurnState(token, callback)
		@sendMessage "YOUR TURN;#{token}"

	yourRoll: (dice, callback) ->
		token = @generateToken()
		@currentState = new WaitingForAnnounceState(token, callback)
		@sendMessage "ROLLED;#{dice};#{token}"

	roundCanceled: (reason) ->
		@sendMessage "ROUND CANCELED;#{reason}"
		@currentState = new InactiveState

	roundStarted: ->
		@sendMessage "ROUND STARTED;testClient:0" #TODO correct players/scores

	announcedDiceBy: (dice, player) ->
		@sendMessage "ANNOUNCED;#{player.name};#{dice}"

	playerLost: (player) ->

	handleMessage: (messageCommand, messageArgs) ->
		@currentState = @currentState.handleMessage messageCommand, messageArgs

	sendMessage: (message) ->
		@sendMessageCallback message

	generateToken: ->
		uuid()

exports.create = (name, sendMessageCallback) ->
	new RemotePlayer(name, sendMessageCallback)

