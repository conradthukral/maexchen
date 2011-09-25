class PlayerStub
	willJoinRound: ->
	roundCanceled: ->
	roundStarted: ->
	yourTurn: ->
	yourRoll: ->
	announcedDiceBy: ->

mia = require '../lib/miaGame'
dice = require '../lib/dice'

describe 'Mia Game', ->
	miaGame = player1 = player2 = player3 = registerPlayers = null
	accept = (question) -> question(true)
	deny = (question) -> question(false)
	roll = (question) -> question(mia.Messages.ROLL)
	see = (question) -> question(mia.Messages.SEE)
	garbage = (question) -> question('GARBAGE')

	beforeEach ->
		miaGame = mia.createGame()
		players = [new PlayerStub, new PlayerStub, new PlayerStub]
		player1 = players[0]
		player2 = players[1]
		player3 = players[2]
		this.addMatchers
			toHavePlayer: (player) -> this.actual.hasPlayer player

		registerPlayers = (numbers...) ->
			for number in numbers
				miaGame.registerPlayer players[number - 1]

	afterEach ->
		miaGame.stop()

	it 'accepts players to register', ->
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
			registerPlayers 1, 2

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

		it 'should reset actualDice', ->
			miaGame.actualDice = 'x'
			miaGame.startRound()
			expect(miaGame.actualDice).toBeNull()

		it 'should reset announcedDice', ->
			miaGame.announcedDice = 'x'
			miaGame.startRound()
			expect(miaGame.announcedDice).toBeNull()

	describe 'next turn', ->
		beforeEach ->
			registerPlayers 1, 2
			miaGame.currentRound.add player1
			miaGame.currentRound.add player2
			miaGame.setBroadcastTimeout 20

		it 'should set the first player in round as currentPlayer', ->
			expect(miaGame.currentPlayer).toBeNull()
			runs ->
				miaGame.nextTurn()
			waits 10
			runs ->
				expect(miaGame.currentPlayer).toBe player1

		it 'should tell the first player in round that it is her turn', ->
			spyOn player1, 'yourTurn'
			spyOn player2, 'yourTurn'
			runs ->
				miaGame.nextTurn()
			waits 10
			runs ->
				expect(player1.yourTurn).toHaveBeenCalled()
				expect(player2.yourTurn).not.toHaveBeenCalled()

		it 'should call rollDice, when player wants to roll', ->
			spyOn miaGame, 'rollDice'
			runs ->
				player1.yourTurn = roll
				miaGame.nextTurn()
			waitsFor (-> miaGame.rollDice.wasCalled), 10

		it 'should call showDice, when player wants to see', ->
			spyOn miaGame, 'showDice'
			runs ->
				player1.yourTurn = see
				miaGame.nextTurn()
			waitsFor (-> miaGame.showDice.wasCalled), 10

		it 'should call currentPlayerLoses, when player fails to answer', ->
			spyOn miaGame, 'currentPlayerLoses'
			runs ->
				player1.yourTurn = garbage
				miaGame.nextTurn()
			waitsFor (-> miaGame.currentPlayerLoses.wasCalled), 10

		it 'should call currentPlayerLoses, when player answers after timeout', ->
			spyOn miaGame, 'currentPlayerLoses'
			spyOn miaGame, 'rollDice'
			runs ->
				player1.yourTurn = (question) -> setTimeout (-> roll(question)), 30
				miaGame.nextTurn()
			waits 50
			runs ->
				expect(miaGame.currentPlayerLoses).toHaveBeenCalled()
				expect(miaGame.rollDice).not.toHaveBeenCalled()

		it 'should call currentPlayerLoses, when player does not answer', ->
			spyOn miaGame, 'currentPlayerLoses'
			runs ->
				player1.yourTurn = ->
				miaGame.nextTurn()
			waits 30
			runs ->
				expect(miaGame.currentPlayerLoses).toHaveBeenCalled()

	describe 'roll dice', ->
		diceRoller =
			roll: -> 'theDice'

		beforeEach ->
			miaGame.registerPlayer player1
			miaGame.currentRound.add player1
			miaGame.setDiceRoller diceRoller
			miaGame.setBroadcastTimeout 20

		it 'should inform the player about their roll', ->
			spyOn player1, 'yourRoll'
			runs ->
				miaGame.rollDice()
			waitsFor (-> player1.yourRoll.wasCalled), 10
			runs ->
				expect(player1.yourRoll.mostRecentCall.args[0]).toBe 'theDice'

		it 'should store the actual roll', ->
			miaGame.rollDice()
			expect(miaGame.actualDice).toBe 'theDice'

		it 'should call announce with the announced dice', ->
			spyOn miaGame, 'announce'
			runs ->
				player1.yourRoll = (dice, announce) -> announce 'announcedDice'
				miaGame.rollDice()
			waitsFor (-> miaGame.announce.wasCalled), 10
			runs ->
				expect(miaGame.announce).toHaveBeenCalledWith 'announcedDice'

		it 'should make the player lose, when she does not announce within time', ->
			spyOn miaGame, 'announce'
			spyOn miaGame, 'currentPlayerLoses'
			runs ->
				player1.yourRoll = (dice, announce) -> setTimeout announce, 30
				miaGame.rollDice()
			waits 50
			runs ->
				expect(miaGame.announce).not.toHaveBeenCalled()
				expect(miaGame.currentPlayerLoses).toHaveBeenCalled()

		it 'should make the player lose, when she does not announce', ->
			spyOn miaGame, 'currentPlayerLoses'
			runs ->
				player1.yourRoll = (dice, announce) ->
				miaGame.rollDice()
			waits 30
			runs ->
				expect(miaGame.currentPlayerLoses).toHaveBeenCalled()

	describe 'annouce', ->
		it 'should store the announced roll, when she announces higher', ->
			miaGame.announcedDice = dice.create 2, 2
			someDice = dice.create 3, 3
			miaGame.announce(someDice)
			expect(miaGame.announcedDice).toBe someDice

		it 'should store the announced roll on first announcement', ->
			someDice = dice.create 3, 3
			miaGame.announce(someDice)
			expect(miaGame.announcedDice).toBe someDice

		it 'should make the player lose, when she does not announce higher', ->
			spyOn miaGame, 'currentPlayerLoses'
			miaGame.announcedDice = dice.create 3, 3
			miaGame.announce(dice.create 2, 2)
			expect(miaGame.currentPlayerLoses).toHaveBeenCalled()

		it 'should broadcast, when she announces wrongly', ->
			spyOn miaGame, 'broadcastAnnouncedDice'
			miaGame.announcedDice = dice.create 3, 3
			miaGame.announce(dice.create 2, 2)
			expect(miaGame.broadcastAnnouncedDice).toHaveBeenCalled()

		it 'should broadcast the announced roll, when she announces validly', ->
			spyOn miaGame, 'broadcastAnnouncedDice'
			miaGame.announce(dice.create 3, 3)
			expect(miaGame.broadcastAnnouncedDice).toHaveBeenCalled()

		it 'should broadcast mia, when she announces mia correctly', ->
			spyOn miaGame, 'broadcastMia'
			miaGame.actualDice = dice.create 2, 1
			miaGame.announce(dice.create 1, 2)
			expect(miaGame.broadcastMia).toHaveBeenCalled()

		it 'should make player lose, when she announces mia wrongly', ->
			spyOn miaGame, 'currentPlayerLoses'
			miaGame.actualDice = dice.create 2, 2
			miaGame.announce(dice.create 1, 2)
			expect(miaGame.currentPlayerLoses).toHaveBeenCalled()

	describe 'when player wants to see', ->
		beforeEach ->
			spyOn miaGame, 'currentPlayerLoses'
			spyOn miaGame, 'lastPlayerLoses'

		it 'should broadcast actual dice', ->
			spyOn miaGame, 'broadcastActualDice'
			miaGame.showDice()
			expect(miaGame.broadcastActualDice).toHaveBeenCalled()

		it 'should make current player lose when no dice are available', ->
			miaGame.showDice()
			expect(miaGame.currentPlayerLoses).toHaveBeenCalled()
			expect(miaGame.lastPlayerLoses).not.toHaveBeenCalled()

		it 'should make last player lose when actualDice differ from announcedDice', ->
			miaGame.actualDice = dice.create 2, 3
			miaGame.announcedDice = dice.create 1, 3
			miaGame.showDice()
			expect(miaGame.currentPlayerLoses).not.toHaveBeenCalled()
			expect(miaGame.lastPlayerLoses).toHaveBeenCalled()

		it 'should make current player lose when actualDice are same as announcedDice', ->
			miaGame.actualDice = dice.create 2, 3
			miaGame.announcedDice = dice.create 2, 3
			miaGame.showDice()
			expect(miaGame.currentPlayerLoses).toHaveBeenCalled()
			expect(miaGame.lastPlayerLoses).not.toHaveBeenCalled()

	describe 'broadcast announced dice', ->
		beforeEach ->
			registerPlayers 1, 2, 3
			miaGame.currentRound.add player2
			miaGame.currentRound.add player3
			
		it 'should tell everybody in current round about the announced dice', ->
			spyOn player1, 'announcedDiceBy'
			spyOn player2, 'announcedDiceBy'
			spyOn player3, 'announcedDiceBy'
			runs ->
				miaGame.announcedDice = 'theDice'
				miaGame.currentPlayer = player2
				miaGame.broadcastAnnouncedDice()
			waitsFor (-> player2.announcedDiceBy.wasCalled), 10
			runs ->
				expect(player2.announcedDiceBy).toHaveBeenCalledWith 'theDice', player2
				expect(player3.announcedDiceBy).toHaveBeenCalledWith 'theDice', player2
				expect(player1.announcedDiceBy).not.toHaveBeenCalled()

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

