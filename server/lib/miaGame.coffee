expireCallback = require '../lib/expireCallback'

# See http://coffeescriptcookbook.com/chapters/arrays/shuffling-array-elements
Array::shuffle = -> @sort -> 0.5 - Math.random()

class PlayerList
	permuteArray = (array) -> array.shuffle()

	constructor: -> @players = []

	size: -> @players.length
	add: (player) -> @players.push player
	hasPlayer: (player) -> player in @players
	first: (fn) ->
		fn @players[0] if @players[0]?

	each: (fn) -> for player in @players
		# "do" makes sure, that player is used with the current value
		# not the last player from the loop
		do (player) -> 
			# call non-blocking
			setTimeout (-> fn player), 0
	permute: -> @players = permuteArray @players

class MiaGame
	constructor: ->
		@players = new PlayerList
		@currentRound = new PlayerList
		@broadcastTimeout = 200
		@diceRoller = require './diceRoller'
		@stopped = false

	registerPlayer: (player) -> @players.add player
	setBroadcastTimeout: (@broadcastTimeout) ->
	setDiceRoller: (@diceRoller) ->
	stop: -> @stopped = true

	newRound: ->
		return if @stopped
		@currentRound = round = new PlayerList
		expirer = @startExpirer =>
			if round.size() == 0
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

	startExpirer: (onExpireAction) ->
		expireCallback.startExpirer
			timeout: @broadcastTimeout
			onExpire: onExpireAction

	startRound: ->
		@permuteCurrentRound()
		@currentRound.each (player) ->
			player.roundStarted()
		setTimeout ( => @nextTurn() ), 0

	permuteCurrentRound: -> @currentRound.permute()

	nextTurn: ->
		answer = @currentRound.first (player) =>
			player.yourTurn (turn) =>
				switch turn
					when 'ROLL' then @rollDice()
					when 'SEE' then @broadcastActualDice()
					else @currentPlayerLoses()

	rollDice: ->
		dice = @diceRoller.roll()
		@currentRound.first (player) ->
			player.yourRoll(dice)

	broadcastActualDice: ->
		
	currentPlayerLoses: ->


exports.createGame = -> new MiaGame

exports.classes =
	MiaGame: MiaGame
	PlayerList: PlayerList

