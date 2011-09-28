class PlayerStub
	constructor: (@name) ->
	willJoinRound: ->
	roundCanceled: ->
	roundStarted: ->
	yourTurn: ->
	yourRoll: ->
	announcedDiceBy: ->
	actualDice: ->
	playerLost: ->
	currentScore: ->

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
		players = [new PlayerStub('player1'), new PlayerStub('player2'), new PlayerStub('player3')]
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
			miaGame.newRound()
			expect(player1.willJoinRound).toHaveBeenCalled()
			expect(player2.willJoinRound).toHaveBeenCalled()

		it 'should have player for current round when she wants to', ->
			player1.willJoinRound = accept
			player2.willJoinRound = accept
			miaGame.newRound()

			expect(miaGame.currentRound).toHavePlayer player1
			expect(miaGame.currentRound).toHavePlayer player2

		it 'should not have player for current round when she does not want to', ->
			player1.willJoinRound = deny
			miaGame.newRound()
			expect(miaGame.currentRound).not.toHavePlayer player1

		it 'should not accept joins for the current round after timeout', ->
			miaGame.setBroadcastTimeout 20
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
			player1.willJoinRound = accept
			player2.willJoinRound = accept
			miaGame.newRound()
			expect(miaGame.startRound).toHaveBeenCalled()

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
		
		it 'should not start a round after the game is stopped', ->
			spyOn miaGame, 'startRound'
			miaGame.setBroadcastTimeout 20
			player1.willJoinRound = accept
			runs ->
				miaGame.newRound()
				miaGame.stop()
			waits 30
			runs ->
				expect(miaGame.startRound).not.toHaveBeenCalled()

	describe 'start round', ->

		it 'should permute the current round when starting a new round', ->
			spyOn miaGame, 'permuteCurrentRound'
			miaGame.startRound()
			expect(miaGame.permuteCurrentRound).toHaveBeenCalled()

		it 'should notify players when starting a new round', ->
			miaGame.permuteCurrentRound = ->
			registerPlayers 1, 2
			spyOn player1, 'roundStarted'
			spyOn player2, 'roundStarted'
			miaGame.currentRound.add player1
			miaGame.currentRound.add player2
			miaGame.startRound()
			
			expect(player1.roundStarted).toHaveBeenCalledWith [player1, player2]
			expect(player2.roundStarted).toHaveBeenCalledWith [player1, player2]

		it 'should call next turn', ->
			spyOn miaGame, 'nextTurn'
			miaGame.startRound()
			expect(miaGame.nextTurn).toHaveBeenCalled()

		it 'should reset actualDice', ->
			miaGame.actualDice = 'x'
			miaGame.startRound()
			expect(miaGame.actualDice).toBeNull()

		it 'should reset announcedDice', ->
			miaGame.announcedDice = 'x'
			miaGame.startRound()
			expect(miaGame.announcedDice).toBeNull()

		it 'should award all participating players a point', ->
			registerPlayers 1, 2
			spyOn miaGame.score, 'increaseFor'
			miaGame.currentRound.add player1
			miaGame.startRound()
			
			expect(miaGame.score.increaseFor).toHaveBeenCalledWith player1
			expect(miaGame.score.increaseFor).not.toHaveBeenCalledWith player2

	describe 'next turn', ->
		beforeEach ->
			registerPlayers 1, 2, 3
			miaGame.currentRound.add player1
			miaGame.currentRound.add player2
			miaGame.currentRound.add player3
			miaGame.setBroadcastTimeout 20

		it 'should iterate over the players', ->
			expect(miaGame.currentPlayer).toBeNull()
			expect(miaGame.lastPlayer).toBeNull()

			miaGame.nextTurn()
			expect(miaGame.currentPlayer).toBe player1
			expect(miaGame.lastPlayer).toBe player3

			miaGame.nextTurn()
			expect(miaGame.currentPlayer).toBe player2
			expect(miaGame.lastPlayer).toBe player1

			miaGame.nextTurn()
			expect(miaGame.currentPlayer).toBe player3
			expect(miaGame.lastPlayer).toBe player2

			miaGame.nextTurn()
			expect(miaGame.currentPlayer).toBe player1
			expect(miaGame.lastPlayer).toBe player3

		it 'should tell the first player in round that it is her turn', ->
			spyOn player1, 'yourTurn'
			spyOn player2, 'yourTurn'
			miaGame.nextTurn()
			expect(player1.yourTurn).toHaveBeenCalled()
			expect(player2.yourTurn).not.toHaveBeenCalled()

		it 'should call rollDice, when player wants to roll', ->
			spyOn miaGame, 'rollDice'
			player1.yourTurn = roll
			miaGame.nextTurn()
			expect(miaGame.rollDice).toHaveBeenCalled()

		it 'should call showDice, when player wants to see', ->
			spyOn miaGame, 'showDice'
			player1.yourTurn = see
			miaGame.nextTurn()
			expect(miaGame.showDice).toHaveBeenCalled()

		it 'should call currentPlayerLoses, when player fails to answer', ->
			spyOn miaGame, 'currentPlayerLoses'
			player1.yourTurn = garbage
			miaGame.nextTurn()
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'invalid turn'

		it 'should call currentPlayerLoses, when player answers after timeout', ->
			spyOn miaGame, 'currentPlayerLoses'
			spyOn miaGame, 'rollDice'
			runs ->
				player1.yourTurn = (question) -> setTimeout (-> roll(question)), 30
				miaGame.nextTurn()
			waitsFor (-> miaGame.currentPlayerLoses.wasCalled), 50
			runs ->
				expect(miaGame.rollDice).not.toHaveBeenCalled()

		it 'should call currentPlayerLoses, when player does not answer', ->
			spyOn miaGame, 'currentPlayerLoses'
			runs ->
				player1.yourTurn = ->
				miaGame.nextTurn()
			waitsFor (-> miaGame.currentPlayerLoses.wasCalled), 50
			runs ->
				expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'failed to take a turn'

	describe 'roll dice', ->
		diceRoller =
			roll: -> 'theDice'

		beforeEach ->
			miaGame.registerPlayer player1
			miaGame.currentPlayer = player1
			miaGame.setDiceRoller diceRoller
			miaGame.setBroadcastTimeout 20
			spyOn miaGame, 'currentPlayerLoses'

		it 'should inform the player about their roll', ->
			spyOn player1, 'yourRoll'
			miaGame.rollDice()
			expect(player1.yourRoll).toHaveBeenCalled()
			expect(player1.yourRoll.mostRecentCall.args[0]).toBe 'theDice'

		it 'should store the actual roll', ->
			miaGame.rollDice()
			expect(miaGame.actualDice).toBe 'theDice'

		it 'should call announce with the announced dice', ->
			spyOn miaGame, 'announce'
			player1.yourRoll = (dice, announce) -> announce 'announcedDice'
			miaGame.rollDice()
			expect(miaGame.announce).toHaveBeenCalledWith 'announcedDice'

		it 'should make the player lose, when she does not announce within time', ->
			spyOn miaGame, 'announce'
			runs ->
				player1.yourRoll = (dice, announce) -> setTimeout announce, 30
				miaGame.rollDice()
			waitsFor (-> miaGame.currentPlayerLoses.wasCalled), 50
			runs ->
				expect(miaGame.announce).not.toHaveBeenCalled()

		it 'should make the player lose, when she does not announce', ->
			runs ->
				player1.yourRoll = (dice, announce) ->
				miaGame.rollDice()
			waitsFor (-> miaGame.currentPlayerLoses.wasCalled), 50
			runs ->
				expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'failed to announce dice'

		it 'should do nothing if the game is stopped', ->
			spyOn player1, 'yourRoll'
			miaGame.stop()
			miaGame.rollDice()
			expect(player1.yourRoll).not.toHaveBeenCalled()

	describe 'announce', ->

		beforeEach ->
			spyOn miaGame, 'currentPlayerLoses'

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
			miaGame.announcedDice = dice.create 3, 3
			miaGame.announce(dice.create 2, 2)
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'announced losing dice'

		it 'should broadcast, when she announces wrongly', ->
			spyOn miaGame, 'broadcastAnnouncedDice'
			miaGame.announcedDice = dice.create 3, 3
			miaGame.announce(dice.create 2, 2)
			expect(miaGame.broadcastAnnouncedDice).toHaveBeenCalled()

		it 'should broadcast the announced roll, when she announces validly', ->
			spyOn miaGame, 'broadcastAnnouncedDice'
			miaGame.announce(dice.create 3, 3)
			expect(miaGame.broadcastAnnouncedDice).toHaveBeenCalledWith dice.create(3, 3)

		it 'should call next turn when she announces validly', ->
			spyOn miaGame, 'nextTurn'
			miaGame.announce(dice.create 3, 3)
			expect(miaGame.nextTurn).toHaveBeenCalled()

		it 'should broadcast mia, when she announces mia correctly', ->
			spyOn miaGame, 'broadcastMia'
			miaGame.actualDice = dice.create 2, 1
			miaGame.announce(dice.create 1, 2)
			expect(miaGame.broadcastMia).toHaveBeenCalled()

		it 'should make player lose, when she announces mia wrongly', ->
			miaGame.actualDice = dice.create 2, 2
			miaGame.announce(dice.create 1, 2)
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'wrongly announced mia'

		it 'should do nothing if the game is stopped', ->
			spyOn miaGame, 'nextTurn'
			miaGame.stop()
			miaGame.announce(dice.create 3, 3)
			expect(miaGame.nextTurn).not.toHaveBeenCalled()

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
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'wanted to see dice before the first roll'
			expect(miaGame.lastPlayerLoses).not.toHaveBeenCalled()

		it 'should make last player lose when actualDice are lower than announcedDice', ->
			miaGame.actualDice = dice.create 3, 1
			miaGame.announcedDice = dice.create 3, 3
			miaGame.showDice()
			expect(miaGame.currentPlayerLoses).not.toHaveBeenCalled()
			expect(miaGame.lastPlayerLoses).toHaveBeenCalledWith 'was caught bluffing'

		it 'should make current lose when actualDice are higher than announcedDice', ->
			miaGame.actualDice = dice.create 3, 3
			miaGame.announcedDice = dice.create 3, 1
			miaGame.showDice()
			expect(miaGame.lastPlayerLoses).not.toHaveBeenCalled()
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'saw that the announcement was true'

		it 'should make current player lose when actualDice are same as announcedDice', ->
			miaGame.actualDice = dice.create 2, 3
			miaGame.announcedDice = dice.create 2, 3
			miaGame.showDice()
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'saw that the announcement was true'
			expect(miaGame.lastPlayerLoses).not.toHaveBeenCalled()

		it 'should do nothing if game is stopped', ->
			spyOn miaGame, 'broadcastActualDice'
			miaGame.stop()
			miaGame.showDice()
			expect(miaGame.broadcastActualDice).not.toHaveBeenCalled()

	describe 'broadcast dice', ->
		beforeEach ->
			registerPlayers 1, 2, 3
			miaGame.currentRound.add player2
			miaGame.currentRound.add player3
			
		it 'should tell everybody in current round about the announced dice', ->
			spyOn player1, 'announcedDiceBy'
			spyOn player2, 'announcedDiceBy'
			spyOn player3, 'announcedDiceBy'
			miaGame.currentPlayer = player2
			miaGame.broadcastAnnouncedDice 'theDice'
			expect(player2.announcedDiceBy).toHaveBeenCalledWith 'theDice', player2
			expect(player3.announcedDiceBy).toHaveBeenCalledWith 'theDice', player2
			expect(player1.announcedDiceBy).not.toHaveBeenCalled()

		it 'should tell everybody in current round about the actual dice', ->
			spyOn player1, 'actualDice'
			spyOn player2, 'actualDice'
			spyOn player3, 'actualDice'
			miaGame.actualDice = 'theDice'
			miaGame.broadcastActualDice()
			expect(player2.actualDice).toHaveBeenCalledWith 'theDice'
			expect(player3.actualDice).toHaveBeenCalledWith 'theDice'
			expect(player1.actualDice).not.toHaveBeenCalled()

	describe 'current player loses', ->
		beforeEach ->
			registerPlayers 1, 2, 3
			miaGame.currentRound.add player2
			miaGame.currentRound.add player3

		it 'should decrease the score', ->
			spyOn miaGame.score, 'decreaseFor'
			miaGame.currentPlayer = player2
			miaGame.currentPlayerLoses 'theReason'
			expect(miaGame.score.decreaseFor).toHaveBeenCalledWith player2
			expect(miaGame.score.decreaseFor).not.toHaveBeenCalledWith player3

		it 'should broadcast player lost to everyone in the round', ->
			spyOn player1, 'playerLost'
			spyOn player2, 'playerLost'
			spyOn player3, 'playerLost'
			miaGame.currentPlayer = player2
			miaGame.currentPlayerLoses 'theReason'
			expect(player2.playerLost).toHaveBeenCalledWith player2, 'theReason'
			expect(player3.playerLost).toHaveBeenCalledWith player2, 'theReason'
			expect(player1.playerLost).not.toHaveBeenCalled()

		it 'should do nothing if game is stopped', ->
			spyOn player2, 'playerLost'
			miaGame.currentPlayer = player2
			miaGame.stop()
			miaGame.currentPlayerLoses 'aReason'
			expect(player2.playerLost).not.toHaveBeenCalled()

		it 'should broadcast the score of all players to all players', ->
			spyOn miaGame, 'broadcastScore'
			miaGame.currentPlayer = player2
			miaGame.currentPlayerLoses 'aReason'
			expect(miaGame.broadcastScore).toHaveBeenCalled()

	describe 'last player loses', ->
		beforeEach ->
			registerPlayers 1, 2, 3
			miaGame.currentRound.add player2
			miaGame.currentRound.add player3

		it 'should decrease the score', ->
			spyOn miaGame.score, 'decreaseFor'
			miaGame.lastPlayer = player2
			miaGame.lastPlayerLoses 'theReason'
			expect(miaGame.score.decreaseFor).toHaveBeenCalledWith player2
			expect(miaGame.score.decreaseFor).not.toHaveBeenCalledWith player3

		it 'should broadcast player lost to everyone in the round', ->
			spyOn player1, 'playerLost'
			spyOn player2, 'playerLost'
			spyOn player3, 'playerLost'
			miaGame.lastPlayer = player2
			miaGame.lastPlayerLoses 'theReason'
			expect(player2.playerLost).toHaveBeenCalledWith player2, 'theReason'
			expect(player3.playerLost).toHaveBeenCalledWith player2, 'theReason'
			expect(player1.playerLost).not.toHaveBeenCalled()

		it 'should do nothing if game is stopped', ->
			spyOn player2, 'playerLost'
			miaGame.lastPlayer = player2
			miaGame.stop()
			miaGame.lastPlayerLoses 'aReason'
			expect(player2.playerLost).not.toHaveBeenCalled()

		it 'should broadcast the score of all players to all players', ->
			spyOn miaGame, 'broadcastScore'
			miaGame.lastPlayer = player2
			miaGame.lastPlayerLoses 'aReason'
			expect(miaGame.broadcastScore).toHaveBeenCalled()

	describe 'broadcast score', ->

		beforeEach ->
			registerPlayers 1, 2

		it 'should send the current score to all players', ->
			spyOn player1, 'currentScore'
			spyOn player2, 'currentScore'
			miaGame.score.all = () -> 'theScore'
			miaGame.currentRound.add player1
			miaGame.broadcastScore()
			expect(player1.currentScore).toHaveBeenCalledWith 'theScore'
			expect(player2.currentScore).toHaveBeenCalledWith 'theScore'

#	describe 'broadcast mia', ->
#		it 'should announce that the following player loses', ->
			

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

