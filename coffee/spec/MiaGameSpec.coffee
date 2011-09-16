class PlayerStub
	willJoinRound: ->

describe 'Mia Game', ->
	miaGame = player1 = player2 = null

	beforeEach ->
		miaGame = require('miaGame').createGame()
		this.addMatchers
			toHavePlayer: (player) -> this.actual.hasPlayer player

	it 'accepts players to register', ->
		player1 = {}
		player2 = {}
		expect(miaGame.players).not.toHavePlayer player1
		miaGame.registerPlayer player1
		expect(miaGame.players).toHavePlayer player1

		expect(miaGame.players).not.toHavePlayer player2
		miaGame.registerPlayer player2
		expect(miaGame.players).toHavePlayer player2

	describe 'broadcasts', ->
		beforeEach ->
			miaGame.registerPlayer player1 = new PlayerStub
			miaGame.registerPlayer player2 = new PlayerStub

		it 'should broadcast new round', ->
			spyOn player1, 'willJoinRound'
			miaGame.newRound()
			expect(player1.willJoinRound).toHaveBeenCalled()

		it 'should have player for this round when she wants to', ->
			spyOn(player1, 'willJoinRound').andReturn(true)
			miaGame.newRound()
			expect(miaGame.currentRound).toHavePlayer player1

		it 'should not have player for this round when she does not want to', ->
			spyOn(player1, 'willJoinRound').andReturn(false)
			miaGame.newRound()
			expect(miaGame.currentRound).not.toHavePlayer player1

