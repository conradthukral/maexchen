# See http://coffeescriptcookbook.com/chapters/arrays/shuffling-array-elements
Array::shuffle = -> @sort -> 0.5 - Math.random()

class PlayerList
	permuteArray = (array) -> array.shuffle()

	constructor: -> @players = []

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

	registerPlayer: (player) -> @players.add player

	newRound: ->
		@currentRound = new PlayerList
		@players.each (player) => # "=>" binds this to MiaGame
			player.willJoinRound (join) =>
				@currentRound.add player if join
		@permuteCurrentRound()

	permuteCurrentRound: -> @currentRound.permute()


exports.createGame = -> new MiaGame

exports.classes =
	MiaGame: MiaGame
	PlayerList: PlayerList

