class PlayerStub
	willJoinRound: ->
	roundCanceled: ->

mia = require '../lib/miaGame'

describe 'Mia Game', ->
	miaGame = player1 = player2 = null

	beforeEach ->
		miaGame = mia.createGame()
		this.addMatchers
			toHavePlayer: (player) -> this.actual.hasPlayer player

	it 'accepts players to register', ->
		player1 = {}
		player2 = {}
		expect(miaGame.players).not.toHavePlayer player1
		miaGame.registerPlayer player1

		expect(miaGame.players).not.toHavePlayer player2
		miaGame.registerPlayer player2

		expect(miaGame.players).toHavePlayer player1
		expect(miaGame.players).toHavePlayer player2

	it 'calls permute on current round', ->
		spyOn miaGame.currentRound, 'permute'
		miaGame.permuteCurrentRound()
		expect(miaGame.currentRound.permute).toHaveBeenCalled()

	describe 'new round', ->
		accept = (question) -> question(true)
		deny = (question) -> question(false)

		beforeEach ->
			miaGame.registerPlayer player1 = new PlayerStub
			miaGame.registerPlayer player2 = new PlayerStub

		afterEach ->
			miaGame.stop()

		it 'should broadcast new round', ->
			spyOn player1, 'willJoinRound'
			spyOn player2, 'willJoinRound'
			runs ->
				miaGame.newRound()
			waits 0
			runs ->
				expect(player1.willJoinRound).toHaveBeenCalled()
				expect(player2.willJoinRound).toHaveBeenCalled()

		it 'should have player for current round when she wants to', ->
			runs ->
				player1.willJoinRound = accept
				player2.willJoinRound = accept
				miaGame.newRound()
				expect(miaGame.currentRound).not.toHavePlayer player1
			waits 0

			runs ->
				expect(miaGame.currentRound).toHavePlayer player1
				expect(miaGame.currentRound).toHavePlayer player1

		it 'should not have player for current round when she does not want to', ->
			runs ->
				player1.willJoinRound = deny
				miaGame.newRound()
			waits 0

			runs ->
				expect(miaGame.currentRound).not.toHavePlayer player1

		it 'should not accept joins for the current round after timeout', ->
			miaGame.setBroadcastTimeout 30
			runs ->
				player1.willJoinRound = (joinRound) ->
					setTimeout (-> joinRound(true)), 40
				miaGame.newRound()
			waits 60

			runs ->
				expect(miaGame.currentRound).not.toHavePlayer player1

		it 'should not have joins for first round in second round', ->
			firstRound = secondRound = null
			runs ->
				player1.willJoinRound = (joinRound) ->
					setTimeout (-> joinRound(true)), 40
				miaGame.newRound()
				firstRound = miaGame.currentRound
			waits 20
			runs ->
				player1.willJoinRound = (joinRound) ->
				miaGame.newRound()
				secondRound = miaGame.currentRound
			waits 30
			runs ->
				expect(firstRound).not.toBe secondRound
				expect(firstRound).toHavePlayer player1
				expect(secondRound).not.toHavePlayer player1

		it 'should start round after all players joined', ->
			spyOn miaGame, 'startRound'
			runs ->
				player1.willJoinRound = accept
				player2.willJoinRound = accept
				miaGame.newRound()
			waits 0
			runs ->
				expect(miaGame.startRound).toHaveBeenCalled()

		it 'should start round after timeout when players are missing', ->
			spyOn miaGame, 'startRound'
			miaGame.setBroadcastTimeout 20
			runs ->
				player1.willJoinRound = accept
				miaGame.newRound()
			waits 15
			runs ->
				expect(miaGame.startRound).not.toHaveBeenCalled()
			waits 15
			runs ->
				expect(miaGame.startRound).toHaveBeenCalled()
			
		it 'should notify players when nobody joins', ->
			spyOn player1, 'roundCanceled'
			spyOn player2, 'roundCanceled'
			miaGame.setBroadcastTimeout 20
			runs ->
				miaGame.newRound()
			waits 30
			runs ->
				expect(player1.roundCanceled).toHaveBeenCalledWith 'no players'
				expect(player2.roundCanceled).toHaveBeenCalledWith 'no players'

		it 'should not start round, but call newRound(), if nobody joined', ->
			spyOn miaGame, 'startRound'
			spyOn(miaGame, 'newRound').andCallThrough()
			miaGame.setBroadcastTimeout 20
			runs ->
				miaGame.newRound()
			waits 15
			runs ->
				expect(miaGame.newRound).toHaveBeenCalled()
				expect(miaGame.newRound.callCount).toBe 1
				expect(miaGame.startRound).not.toHaveBeenCalled()
			waits 15
			runs ->
				expect(miaGame.startRound).not.toHaveBeenCalled()
				expect(miaGame.newRound.callCount).toBe 2

		it 'should permute the current round when starting a new round', ->
			spyOn miaGame, 'permuteCurrentRound'
			miaGame.startRound()
			expect(miaGame.permuteCurrentRound).toHaveBeenCalled()

describe 'permutation', ->
	list1 = list2 = {}

	beforeEach ->
		this.addMatchers

			toHaveEqualLength: (other) ->
				this.actual.length == other.length

			toEqualArray: (other) ->
				return false unless this.actual.length == other.length
				for key, value of other
					return false unless this.actual[key] == value
				true

		list1 = new mia.classes.PlayerList
		list2 = new mia.classes.PlayerList
		for value in [1..100]
			list1.add value
			list2.add value

	it 'should have same number of objects after permutation', ->
			expect(list1.players).toEqualArray(list2.players)
			list1.permute()
			expect(list1.players).toHaveEqualLength(list2.players)

	it 'should not have same order of objects after permutation', ->
			expect(list1.players).toEqualArray(list2.players)
			list1.permute()
			expect(list1.players).not.toEqualArray(list2.players)

