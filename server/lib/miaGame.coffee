expireCallback = require '../lib/expireCallback'

# See http://coffeescriptcookbook.com/chapters/arrays/shuffling-array-elements
Array::shuffle = -> @sort -> 0.5 - Math.random()

Messages =
	ROLL: {}
	SEE: {}

class PlayerList
	constructor: -> @players = []

	size: -> @players.length
	isEmpty: -> @players.length == 0
	add: (player) -> @players.push player
	hasPlayer: (player) -> player in @players
	permute: -> @players.shuffle()

	first: (fn) ->
		return if @isEmpty()
		fn @players[0]

	each: (fn) -> @players.forEach(fn)
	
	collect: (predicate) ->
		result = []
		(result.push player if predicate(player)) for player in @players
		result

	nextPlayer: () ->
		if @currentPlayer? and @currentPlayer < @size() - 1
			++@currentPlayer
			@lastPlayer = @currentPlayer - 1
		else
			@currentPlayer = 0
			@lastPlayer = @size() - 1
		[@players[@currentPlayer], @players[@lastPlayer]]

class MiaGame
	constructor: ->
		@players = new PlayerList
		@currentRound = new PlayerList
		@broadcastTimeout = 200
		@diceRoller = require './diceRoller'
		@stopped = false
		@actualDice = null
		@announcedDice = null
		@currentPlayer = null
		@lastPlayer = null
		@score = require('./score').create()

	registerPlayer: (player) -> @players.add player
	setBroadcastTimeout: (@broadcastTimeout) ->
	setDiceRoller: (@diceRoller) ->
	stop: -> @stopped = true

	newRound: ->
		return if @stopped
		@currentRound = round = new PlayerList
		expirer = @startExpirer =>
			return if @stopped
			if round.isEmpty()
				@cancelRound 'no players'
			else
				@startRound()

		@players.each (player) => # "=>" binds this to MiaGame
			answerJoining = (join) =>
				round.add player if join
				if round.size() == @players.size()
					expirer.cancelExpireActions()
					@startRound()
			player.willJoinRound expirer.makeExpiring(answerJoining)

	startRound: ->
		@permuteCurrentRound()
		@actualDice = null
		@announcedDice = null
		@currentRound.each (player) =>
			@score.increaseFor player
			player.roundStarted @currentRound.players
		if @currentRound.size() > 1
			@nextTurn()
		else
			@cancelRound 'only one player'
	
	cancelRound: (reason) ->
		@players.each (player) ->
			player.roundCanceled reason
		@broadcastScore()
		@newRound()

	permuteCurrentRound: -> @currentRound.permute()

	nextTurn: ->
		[@currentPlayer, @lastPlayer] = @currentRound.nextPlayer()
		return unless @currentPlayer

		expirer = @startExpirer (=> @currentPlayerLoses 'failed to take a turn'), true

		question = expirer.makeExpiring (turn) =>
			switch turn
				when Messages.ROLL then @rollDice()
				when Messages.SEE then @showDice()
				else @currentPlayerLoses 'invalid turn'

		@currentPlayer.yourTurn question

	rollDice: ->
		return if @stopped
		@actualDice = dice = @diceRoller.roll()

		expirer = @startExpirer (=> @currentPlayerLoses 'failed to announce dice'), true

		announce = expirer.makeExpiring (announcedDice) =>
			@announce(announcedDice)
		
		@currentPlayer.yourRoll dice, announce

	announce: (dice) ->
		return if @stopped
		@broadcastAnnouncedDice dice
		if not @announcedDice? or dice.isHigherThan @announcedDice
			@announcedDice = dice
			if dice.isMia()
				@miaIsAnnounced()
			else
				@nextTurn()
		else
			@currentPlayerLoses 'announced losing dice'

	broadcastAnnouncedDice: (dice) ->
		@currentRound.each (player) =>
			player.announcedDiceBy dice, @currentPlayer

	miaIsAnnounced: ->
		@broadcastActualDice()
		if @actualDice.isMia()
			@everybodyButTheCurrentPlayerLoses 'mia'
		else
			@currentPlayerLoses 'wrongly announced mia'

	showDice: ->
		return if @stopped
		@broadcastActualDice()
		if not @actualDice?
			@currentPlayerLoses 'wanted to see dice before the first roll'
		else if @announcedDice.isHigherThan @actualDice
			@lastPlayerLoses 'was caught bluffing'
		else
			@currentPlayerLoses 'saw that the announcement was true'

	broadcastActualDice: ->
		@currentRound.each (player) =>
			player.actualDice @actualDice
		
	currentPlayerLoses: (reason) -> @playersLose [@currentPlayer], reason

	lastPlayerLoses: (reason) -> @playersLose [@lastPlayer], reason

	everybodyButTheCurrentPlayerLoses: (reason) ->
		losingPlayers = @currentRound.collect (player) => player isnt @currentPlayer
		@playersLose losingPlayers, reason

	playersLose: (losingPlayers, reason) ->
		return if @stopped
		for player in losingPlayers
			@score.decreaseFor player
		@currentRound.each (player) ->
			player.playerLost losingPlayers, reason
		@broadcastScore()
		@newRound()

	broadcastScore: ->
		allScores = @score.all()
		@players.each (player) =>
			player.currentScore allScores

	startExpirer: (onExpireAction, cancelExpireAction = false) ->
		expireCallback.startExpirer
			timeout: @broadcastTimeout
			onExpire: onExpireAction ? ->
			cancelExpireAction: cancelExpireAction

exports.createGame = -> new MiaGame

exports.Messages = Messages
exports.classes =
	MiaGame: MiaGame
	PlayerList: PlayerList

