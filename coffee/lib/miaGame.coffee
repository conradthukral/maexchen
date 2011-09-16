class PlayerList
	constructor: -> @players = []

	add: (player) -> @players.push player
	hasPlayer: (player) -> player in @players
	each: (fn) -> fn player for player in @players

class MiaGame

	constructor: ->
		@players = new PlayerList
		@currentRound = new PlayerList

	registerPlayer: (player) -> @players.add player

	newRound: ->
		@currentRound = new PlayerList
		@players.each (player) => # "=>" binds this to MiaGame
			@currentRound.add player if player.willJoinRound()


exports.createGame = -> new MiaGame

