# See http://coffeescriptcookbook.com/chapters/arrays/shuffling-array-elements
Array::shuffle = -> @sort -> 0.5 - Math.random()

class PlayerList
	permuteArray = (array) -> array.shuffle()

	constructor: -> @players = []

	size: -> @players.length
	add: (player) -> @players.push player
	hasPlayer: (player) -> player in @players
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
		@timeout = null

	registerPlayer: (player) -> @players.add player
	setBroadcastTimeout: (@broadcastTimeout) ->
	stop: -> clearTimeout(@timeout)

	newRound: ->
		@currentRound = round = new PlayerList
		mayJoin = true
		closeJoiningAndStartRound = =>
			mayJoin = false
			if round.size() == 0
				@players.each (player) ->
					player.roundCanceled 'no players'
				@newRound()
			else
				@startRound()

		@timeout = setTimeout closeJoiningAndStartRound, @broadcastTimeout

		@players.each (player) => # "=>" binds this to MiaGame
			player.willJoinRound (join) =>
				round.add player if join and mayJoin
				@startRound() if round.size() == @players.size()

	startRound: ->
		@permuteCurrentRound()
		@currentRound.each (player) =>
			player.roundStarted()

	permuteCurrentRound: -> @currentRound.permute()

exports.createGame = -> new MiaGame

exports.classes =
	MiaGame: MiaGame
	PlayerList: PlayerList

