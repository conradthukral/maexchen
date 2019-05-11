# See http://coffeescriptcookbook.com/chapters/arrays/shuffling-array-elements
Array::shuffle = -> @sort -> 0.5 - Math.random()

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

exports.empty = -> new PlayerList()
