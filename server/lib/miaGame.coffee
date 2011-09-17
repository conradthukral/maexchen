# See http://coffeescriptcookbook.com/chapters/arrays/shuffling-array-elements
Array::shuffle = -> @sort -> 0.5 - Math.random()

class PlayerList
	permuteArray = (array) -> array.shuffle()

	constructor: -> @players = []

	add: (player) -> @players.push player
	hasPlayer: (player) -> player in @players
	each: (fn) -> fn player for player in @players
	permute: -> @players = permuteArray @players

class MiaGame
	constructor: ->
		@players = new PlayerList
		@currentRound = new PlayerList

	registerPlayer: (player) -> @players.add player

	newRound: ->
		@currentRound = new PlayerList
		@players.each (player) => # "=>" binds this to MiaGame
			@currentRound.add player if player.willJoinRound()
		@permuteCurrentRound()

	permuteCurrentRound: -> @currentRound.permute()


exports.createGame = -> new MiaGame

exports.classes =
	MiaGame: MiaGame
	PlayerList: PlayerList

