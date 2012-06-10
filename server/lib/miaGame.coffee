expireCallback = require '../lib/expireCallback'

# See http://coffeescriptcookbook.com/chapters/arrays/shuffling-array-elements
Array::shuffle = -> @sort -> 0.5 - Math.random()

Messages =
	ROLL: {}
	SEE: {}

class PlayerList
	constructor: -> @players = []

	size: -> @realPlayers().length
	isEmpty: -> @size() == 0
	hasPlayer: (player) -> player in @players
	permute: -> @players.shuffle()

	add: (newPlayer) ->
		@players = @collect (existingPlayer) -> existingPlayer.name != newPlayer.name
		@players.push newPlayer

	first: (fn) ->
		return if @isEmpty()
		fn @players[0]

	each: (fn) -> @players.forEach fn

	eachRealPlayer: (fn) -> @realPlayers().forEach fn

	realPlayers: -> @collect (player) -> !player.isSpectator?

	collect: (predicate) ->
		player for player in @players when predicate(player)

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
		@roundNumber = 0
		@startRoundsEarly = true

	registerPlayer: (player) -> @players.add player
	registerSpectator: (player) ->
		player.isSpectator = true
		@players.add player
	setBroadcastTimeout: (@broadcastTimeout) ->
	setDiceRoller: (@diceRoller) ->
	doNotStartRoundsEarly: -> @startRoundsEarly = false

	start: -> @newRound() if @roundNumber == 0
	stop: -> @stopped = true

	newRound: ->
		return if @stopped
		@roundNumber++
		@currentRound = round = new PlayerList
		expirer = @startExpirer =>
			return if @stopped
			if @players.isEmpty()
				@newRound()
			else if round.isEmpty()
				@cancelRound 'NO_PLAYERS'
			else
				@startRound()
		@players.eachRealPlayer (player) => # "=>" binds this to MiaGame
			answerJoining = (join) =>
				round.add player if join
				if @startRoundsEarly and round.size() == @players.size()
					expirer.cancelExpireActions()
					@startRound()
			player.willJoinRound expirer.makeExpiring(answerJoining)

	startRound: ->
		@permuteRound(@currentRound)
		@actualDice = null
		@announcedDice = null
		@currentRound.each (player) =>
			@score.increaseFor player
		@players.each (player) =>
			player.roundStarted @roundNumber, @currentRound.players
		if @currentRound.size() > 1
			@nextTurn()
		else
			@cancelRound 'ONLY_ONE_PLAYER'
	
	cancelRound: (reason) ->
		@players.each (player) ->
			player.roundCanceled reason
		@broadcastScore()
		@newRound()

	permuteRound: (round) -> round.permute()

	nextTurn: ->
		[@currentPlayer, @lastPlayer] = @currentRound.nextPlayer()
		return unless @currentPlayer

		expirer = @startExpirer (=> @currentPlayerLoses 'DID_NOT_TAKE_TURN'), true

		question = expirer.makeExpiring (turn) =>
			switch turn
				when Messages.ROLL then @rollDice()
				when Messages.SEE then @showDice()
				else @currentPlayerLoses 'INVALID_TURN'

		@currentPlayer.yourTurn question

	rollDice: ->
		return if @stopped
		@players.each (player) =>
			player.playerRolls @currentPlayer
		@actualDice = dice = @diceRoller.roll()

		expirer = @startExpirer (=> @currentPlayerLoses 'DID_NOT_ANNOUNCE'), true

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
			@currentPlayerLoses 'ANNOUNCED_LOSING_DICE'

	broadcastAnnouncedDice: (dice) ->
		@players.each (player) =>
			player.announcedDiceBy dice, @currentPlayer

	miaIsAnnounced: ->
		@broadcastActualDice()
		if @actualDice.isMia()
			@everybodyButTheCurrentPlayerLoses 'MIA'
		else
			@currentPlayerLoses 'LIED_ABOUT_MIA'

	showDice: ->
		return if @stopped
		@players.each (player) =>
			player.playerWantsToSee @currentPlayer
		if not @actualDice?
			@currentPlayerLoses 'SEE_BEFORE_FIRST_ROLL'
			return
		@broadcastActualDice()
		if @announcedDice.isHigherThan @actualDice
			@lastPlayerLoses 'CAUGHT_BLUFFING'
		else
			@currentPlayerLoses 'SEE_FAILED'

	broadcastActualDice: ->
		@players.each (player) =>
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
		@players.each (player) ->
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

