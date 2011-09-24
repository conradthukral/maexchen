class PlayerStub
	willJoinRound: ->
	roundCanceled: ->
	roundStarted: ->
	yourTurn: ->
	yourRoll: ->

mia = require '../lib/miaGame'

describe 'Mia Game', ->
	miaGame = player1 = player2 = null
	accept = (question) -> question(true)
	deny = (question) -> question(false)
	roll = (question) -> question('ROLL')
	see = (question) -> question('SEE')
	garbage = (question) -> question('GARBAGE')

	beforeEach ->
		miaGame = mia.createGame()
		this.addMatchers
			toHavePlayer: (player) -> this.actual.hasPlayer player

	afterEach ->
		miaGame.stop()

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

		beforeEach ->
			miaGame.registerPlayer player1 = new PlayerStub
			miaGame.registerPlayer player2 = new PlayerStub

		it 'should broadcast new round', ->
			spyOn player1, 'willJoinRound'
			spyOn player2, 'willJoinRound'
			runs ->
				miaGame.newRound()
			waitsFor (-> player1.willJoinRound.wasCalled), 20
			waitsFor (-> player2.willJoinRound.wasCalled), 20

		it 'should have player for current round when she wants to', ->
			runs ->
				player1.willJoinRound = accept
				player2.willJoinRound = accept
				miaGame.newRound()
				expect(miaGame.currentRound).not.toHavePlayer player1
			waitsFor (-> miaGame.currentRound.hasPlayer player1), 20
			waitsFor (-> miaGame.currentRound.hasPlayer player2), 20

		it 'should not have player for current round when she does not want to', ->
			runs ->
				player1.willJoinRound = deny
				miaGame.newRound()
			waits 20
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
				player1.willJoinRound = ->
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
			waitsFor (-> miaGame.startRound.wasCalled), 20

		it 'should start round after timeout when players are missing', ->
			spyOn miaGame, 'startRound'
			miaGame.setBroadcastTimeout 40
			runs ->
				player1.willJoinRound = accept
				miaGame.newRound()
			waits 20
			runs ->
				expect(miaGame.startRound).not.toHaveBeenCalled()
			waitsFor (-> miaGame.startRound.wasCalled), 30
			
		it 'should notify players when nobody joins', ->
			spyOn player1, 'roundCanceled'
			spyOn player2, 'roundCanceled'
			miaGame.setBroadcastTimeout 20
			runs ->
				miaGame.newRound()
			waitsFor (-> player1.roundCanceled.wasCalled), 40
			runs ->
				expect(player1.roundCanceled).toHaveBeenCalledWith 'no players'
				expect(player2.roundCanceled).toHaveBeenCalledWith 'no players'

		it 'should not start round, but call newRound(), if nobody joined', ->
			spyOn miaGame, 'startRound'
			spyOn(miaGame, 'newRound').andCallThrough()
			miaGame.setBroadcastTimeout 50
			runs ->
				miaGame.newRound()
			waits 30
			runs ->
				expect(miaGame.newRound.callCount).toBe 1
				expect(miaGame.startRound).not.toHaveBeenCalled()
			waits 40
			runs ->
				expect(miaGame.startRound).not.toHaveBeenCalled()
				expect(miaGame.newRound.callCount).toBe 2

	describe 'start round', ->

		it 'should permute the current round when starting a new round', ->
			spyOn miaGame, 'permuteCurrentRound'
			miaGame.startRound()
			expect(miaGame.permuteCurrentRound).toHaveBeenCalled()

		it 'should notify players when starting a new round', ->
			miaGame.registerPlayer player1 = new PlayerStub
			miaGame.registerPlayer player2 = new PlayerStub
			spyOn player1, 'roundStarted'
			spyOn player2, 'roundStarted'
			player1.willJoinRound = accept
			player2.willJoinRound = accept
			miaGame.newRound()
			
			waitsFor (-> player1.roundStarted.wasCalled), 50
			waitsFor (-> player2.roundStarted.wasCalled), 50

		it 'should call next turn', ->
			spyOn miaGame, 'nextTurn'
			miaGame.startRound()
			waitsFor (-> miaGame.nextTurn.wasCalled), 50

	describe 'next turn', ->
		beforeEach ->
			miaGame.registerPlayer player1 = new PlayerStub
			miaGame.registerPlayer player2 = new PlayerStub
			miaGame.currentRound.add player1
			miaGame.currentRound.add player2

		it 'should tell the first player in round that it is her turn', ->
			spyOn player1, 'yourTurn'
			spyOn player2, 'yourTurn'
			miaGame.nextTurn()
			expect(player1.yourTurn).toHaveBeenCalled()
			expect(player2.yourTurn).not.toHaveBeenCalled()

		it 'should call rollDice, when player wants to roll', ->
			player1.yourTurn = roll
			spyOn miaGame, 'rollDice'
			miaGame.nextTurn()
			expect(miaGame.rollDice).toHaveBeenCalled()

		it 'should call broadcastActualDice, when player wants to see', ->
			player1.yourTurn = see
			spyOn miaGame, 'broadcastActualDice'
			miaGame.nextTurn()
			expect(miaGame.broadcastActualDice).toHaveBeenCalled()

		it 'should call currentPlayerLoses, when player fails to answer', ->
			player1.yourTurn = garbage
			spyOn miaGame, 'currentPlayerLoses'
			miaGame.nextTurn()
			expect(miaGame.currentPlayerLoses).toHaveBeenCalled()

		it 'should call currentPlayerLoses, when player answers after timeout', ->
			miaGame.setBroadcastTimeout 20
			runs ->
				player1.yourTurn = (question) -> setTimeout (-> roll(question)), 30
				spyOn miaGame, 'currentPlayerLoses'
				spyOn miaGame, 'rollDice'
				miaGame.nextTurn()
			waits 50
			runs ->
				expect(miaGame.currentPlayerLoses).toHaveBeenCalled()
				expect(miaGame.rollDice).not.toHaveBeenCalled()

	describe 'roll dice', ->
		diceRoller =
			roll: ->

		beforeEach ->
			miaGame.registerPlayer player1 = new PlayerStub
			miaGame.registerPlayer player2 = new PlayerStub
			miaGame.currentRound.add player1
			miaGame.currentRound.add player2
			miaGame.setDiceRoller diceRoller

		it 'should inform the player about their roll', ->
			spyOn(diceRoller, 'roll').andReturn "theDice"
			spyOn(player1, 'yourRoll')

			miaGame.rollDice()
			
			expect(player1.yourRoll).toHaveBeenCalledWith "theDice"


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

