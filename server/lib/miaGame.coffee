expireCallback = require '../lib/expireCallback'

# See http://coffeescriptcookbook.com/chapters/arrays/shuffling-array-elements
Array::shuffle = -> @sort -> 0.5 - Math.random()

class PlayerList
	constructor: -> @players = []

	size: -> @players.length
	isEmpty: -> @players.length == 0
	add: (player) -> @players.push player
	hasPlayer: (player) -> player in @players
	permute: -> @players.shuffle()

	first: (fn) ->
		return if @isEmpty()
		setTimeout (=> fn @players[0]), 0

	each: (fn) -> for player in @players
		# "do" makes sure, that player is used with the current value
		# not the last player from the loop
		do (player) -> 
			# call non-blocking
			setTimeout (-> fn player), 0

class MiaGame
	constructor: ->
		@players = new PlayerList
		@currentRound = new PlayerList
		@broadcastTimeout = 200
		@diceRoller = require './diceRoller'
		@stopped = false
		@actualDice = null

	registerPlayer: (player) -> @players.add player
	setBroadcastTimeout: (@broadcastTimeout) ->
	setDiceRoller: (@diceRoller) ->
	stop: -> @stopped = true

	newRound: ->
		return if @stopped
		@currentRound = round = new PlayerList
		expirer = @startExpirer =>
			if round.isEmpty()
				@players.each (player) ->
					player.roundCanceled 'no players'
				@newRound()
			else
				@startRound()

		@players.each (player) => # "=>" binds this to MiaGame
			answerJoining = (join) =>
				round.add player if join
				@startRound() if round.size() == @players.size()
			player.willJoinRound expirer.makeExpiring(answerJoining)

	startRound: ->
		@permuteCurrentRound()
		@actualDice = null
		@currentRound.each (player) ->
			player.roundStarted()
		@nextTurn()

	permuteCurrentRound: -> @currentRound.permute()

	nextTurn: ->
		expirer = @startExpirer @currentPlayerLoses

		question = expirer.makeExpiring (turn) =>
			switch turn
				when 'ROLL' then @rollDice()
				when 'SEE' then @broadcastActualDice()
				else @currentPlayerLoses()

		@currentRound.first (player) =>
			player.yourTurn question

	rollDice: ->
		@actualDice = dice = @diceRoller.roll()
		@currentRound.first (player) ->
			player.yourRoll(dice)

	broadcastActualDice: ->
		
	currentPlayerLoses: ->

	startExpirer: (onExpireAction) ->
		expireCallback.startExpirer
			timeout: @broadcastTimeout
			onExpire: onExpireAction

exports.createGame = -> new MiaGame

exports.classes =
	MiaGame: MiaGame
	PlayerList: PlayerList

