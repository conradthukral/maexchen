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

	each: (fn) -> for player in @players
		# "do" makes sure, that player is used with the current value
		# not the last player from the loop
		do (player) ->
			# call non-blocking
			fn player

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
				@players.each (player) ->
					player.roundCanceled 'no players'
				@newRound()
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
		@currentRound.each (player) ->
			player.roundStarted()
		@nextTurn()

	permuteCurrentRound: -> @currentRound.permute()

	nextTurn: ->
		@currentRound.first (player) => @currentPlayer = player

		expirer = @startExpirer (=> @currentPlayerLoses 'failed to take a turn'), true

		question = expirer.makeExpiring (turn) =>
			switch turn
				when Messages.ROLL then @rollDice()
				when Messages.SEE then @showDice()
				else @currentPlayerLoses 'invalid turn'

		@currentRound.first (player) ->
			player.yourTurn question

	rollDice: ->
		@actualDice = dice = @diceRoller.roll()

		expirer = @startExpirer (=> @currentPlayerLoses 'failed to announce dice'), true

		announce = expirer.makeExpiring (announcedDice) =>
			@announce(announcedDice)
		
		@currentRound.first (player) ->
			player.yourRoll dice, announce

	announce: (dice) ->
		@broadcastAnnouncedDice dice
		if not @announcedDice? or dice.isHigherThan @announcedDice
			@announcedDice = dice
			if dice.isMia()
				@miaIsAnnounced()
		else
			@currentPlayerLoses 'announced losing dice'

	broadcastAnnouncedDice: (dice) ->
		@currentRound.each (player) =>
			player.announcedDiceBy dice, @currentPlayer

	miaIsAnnounced: ->
		if @actualDice.isMia()
			@broadcastMia()
		else
			@currentPlayerLoses 'wrongly announced mia'

	broadcastMia: ->

	showDice: ->
		@broadcastActualDice()
		if not @actualDice?
			@currentPlayerLoses 'wanted to see dice before the first roll'
		else if @actualDice.equals(@announcedDice)
			@currentPlayerLoses 'saw that the announcement was true'
		else
			@lastPlayerLoses 'was caught bluffing'

	broadcastActualDice: ->
		
	currentPlayerLoses: (reason) ->
		@currentRound.each (player) =>
			player.playerLost @currentPlayer, reason

	lastPlayerLoses: (reason) ->

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

