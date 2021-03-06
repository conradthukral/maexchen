mia = require '../lib/miaGame'
playerList = require '../lib/playerList'
dice = require '../lib/dice'
{ delay, waitFor } = require './waitUtils'

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
	playerRolls: ->
	playerWantsToSee: ->

describe 'Mia Game', ->
	miaGame = player1 = player2 = player3 = player4 = registerPlayers = null
	accept = (question) -> question(true)
	deny = (question) -> question(false)
	roll = (question) -> question(mia.Messages.ROLL)
	see = (question) -> question(mia.Messages.SEE)
	garbage = (question) -> question('GARBAGE')

	beforeEach ->
		miaGame = mia.createGame()
		players = [new PlayerStub('player1'), new PlayerStub('player2'), new PlayerStub('player3'), new PlayerStub('player4')]
		player1 = players[0]
		player2 = players[1]
		player3 = players[2]
		player4 = players[3]
		jasmine.addMatchers
			toHavePlayer: ->
				compare: (actual, expected) ->
					passed = actual.hasPlayer expected
					result =
						pass: passed
						message: "expected #{actual.players}#{' not' unless passed} to have player #{expected.name}"

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

	it 'accepts spectators to register', ->
		expect(miaGame.players).not.toHavePlayer player1
		miaGame.registerSpectator player1

		expect(miaGame.players).toHavePlayer player1

	it 'should not count spectators as players', ->
		miaGame.registerSpectator player1
		expect(miaGame.players.size()).toBe 0

	it 'overwrites previous players with the same name on register', ->
		oldPlayer = name: 'theName'
		newPlayer = name: 'theName'
		
		miaGame.registerPlayer oldPlayer
		miaGame.registerPlayer newPlayer

		expect(miaGame.players).toHavePlayer newPlayer
		expect(miaGame.players).not.toHavePlayer oldPlayer

	it 'delegates permute to the round', ->
		round = permute: ->
		spyOn round, 'permute'
		miaGame.permuteRound(round)
		expect(round.permute).toHaveBeenCalled()

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

		it 'should not ask spectators to join rounds', ->
			spyOn player3, 'willJoinRound'
			miaGame.registerSpectator player3
			miaGame.newRound()
			expect(player3.willJoinRound).not.toHaveBeenCalled()

		it 'should not accept joins for the current round after timeout', ->
			miaGame.setBroadcastTimeout 20
			player1.willJoinRound = (joinRound) -> setTimeout (-> joinRound(true)), 40
			miaGame.newRound()
			await delay 60, ->
				expect(miaGame.currentRound).not.toHavePlayer player1

		it 'should not have joins for first round in second round', ->
			player1.willJoinRound = (joinRound) ->
				setTimeout (-> joinRound(true)), 40
			miaGame.newRound()
			firstRound = miaGame.currentRound
			
			secondRound = await delay 20, ->
				player1.willJoinRound = ->
				miaGame.newRound()
				miaGame.currentRound

			await delay 20, ->
				expect(firstRound).not.toBe secondRound
				expect(firstRound).toHavePlayer player1
				expect(secondRound).not.toHavePlayer player1

		it 'should start round early after all players joined', ->
			spyOn miaGame, 'startRound'
			player1.willJoinRound = accept
			player2.willJoinRound = accept
			miaGame.newRound()
			expect(miaGame.startRound).toHaveBeenCalled()

		it 'should not start rounds early if told not to', ->
			spyOn miaGame, 'startRound'
			player1.willJoinRound = accept
			player2.willJoinRound = accept
			miaGame.setBroadcastTimeout 20
			miaGame.doNotStartRoundsEarly()

			miaGame.newRound()
			expect(miaGame.startRound).not.toHaveBeenCalled()

			waitFor 30, -> miaGame.startRound.calls.any()

		it 'should neither start round nor cancel it when only spectators are in the game', ->
			spyOn miaGame, 'startRound'
			spyOn miaGame, 'cancelRound'
			miaGame.players = playerList.empty()
			miaGame.registerSpectator player1
			miaGame.setBroadcastTimeout 20
			
			miaGame.newRound()
			expect(miaGame.startRound).not.toHaveBeenCalled()
			expect(miaGame.cancelRound).not.toHaveBeenCalled()

			await delay 40, ->
				expect(miaGame.startRound).not.toHaveBeenCalled()
				expect(miaGame.cancelRound).not.toHaveBeenCalled()

		it 'should start round after timeout when players are missing', ->
			spyOn miaGame, 'startRound'
			miaGame.setBroadcastTimeout 40
			player1.willJoinRound = accept
			miaGame.newRound()
			await delay 20, ->
				expect(miaGame.startRound).not.toHaveBeenCalled()
			await waitFor 30, -> miaGame.startRound.calls.any()
			
		it 'should cancel the round when nobody joins', ->
			spyOn miaGame, 'cancelRound'
			spyOn miaGame, 'startRound'
			miaGame.setBroadcastTimeout 20
			miaGame.newRound()
			await waitFor 40, -> miaGame.cancelRound.calls.any()
			expect(miaGame.cancelRound).toHaveBeenCalledWith 'NO_PLAYERS'
			expect(miaGame.startRound).not.toHaveBeenCalled()

		it 'should not start a round after the game is stopped', ->
			spyOn miaGame, 'startRound'
			miaGame.setBroadcastTimeout 20
			player1.willJoinRound = accept
		
			miaGame.newRound()
			miaGame.stop()
		
			await delay 30, ->
				expect(miaGame.startRound).not.toHaveBeenCalled()

		it 'should set the round number to 1 for the first round', ->
			miaGame.newRound()
			expect(miaGame.roundNumber).toBe 1
		
		it 'should increment the round number', ->
			miaGame.roundNumber = 41
			miaGame.newRound()
			expect(miaGame.roundNumber).toBe 42

	describe 'start round', ->

		it 'should permute the current round when starting a new round', ->
			spyOn miaGame, 'permuteRound'
			miaGame.startRound()
			expect(miaGame.permuteRound).toHaveBeenCalledWith miaGame.currentRound

		it 'should notify all players when starting a new round', ->
			miaGame.permuteRound = ->
			registerPlayers 1, 2
			spyOn player1, 'roundStarted'
			spyOn player2, 'roundStarted'
			miaGame.currentRound.add player1
			miaGame.roundNumber = 42
			miaGame.startRound()
			expect(player1.roundStarted).toHaveBeenCalledWith 42, [player1]
			expect(player2.roundStarted).toHaveBeenCalledWith 42, [player1]

		it 'should call next turn', ->
			spyOn miaGame, 'nextTurn'
			miaGame.currentRound.add player1
			miaGame.currentRound.add player2
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

		it 'should immediately cancel rounds with only a single player', ->
			registerPlayers 1
			spyOn miaGame, 'cancelRound'
			spyOn miaGame, 'nextTurn'
			miaGame.currentRound.add player1
			miaGame.startRound()
			expect(miaGame.cancelRound).toHaveBeenCalledWith 'ONLY_ONE_PLAYER'
			expect(miaGame.nextTurn).not.toHaveBeenCalled()

	describe 'cancel round', ->

		beforeEach ->
			registerPlayers 1, 2

		it 'should notify players', ->
			spyOn player1, 'roundCanceled'
			spyOn player2, 'roundCanceled'
			miaGame.cancelRound 'theReason'
			expect(player1.roundCanceled).toHaveBeenCalledWith 'theReason'
			expect(player2.roundCanceled).toHaveBeenCalledWith 'theReason'

		it 'should broadcast the score', ->
			spyOn miaGame, 'broadcastScore'
			miaGame.cancelRound()
			expect(miaGame.broadcastScore).toHaveBeenCalled()

		it 'should call new round', ->
			spyOn miaGame, 'newRound'
			miaGame.cancelRound()
			expect(miaGame.newRound).toHaveBeenCalled()

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
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'INVALID_TURN'

		it 'should call currentPlayerLoses, when player answers after timeout', ->
			spyOn miaGame, 'currentPlayerLoses'
			spyOn miaGame, 'rollDice'

			player1.yourTurn = (question) -> setTimeout (-> roll(question)), 30
			miaGame.nextTurn()

			await delay 50, ->
				expect(miaGame.currentPlayerLoses).toHaveBeenCalled()
				expect(miaGame.rollDice).not.toHaveBeenCalled()

		it 'should call currentPlayerLoses, when player does not answer', ->
			spyOn miaGame, 'currentPlayerLoses'
			player1.yourTurn = ->
			miaGame.nextTurn()
			
			await waitFor 50, -> miaGame.currentPlayerLoses.calls.any()
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'DID_NOT_TAKE_TURN'

	describe 'roll dice', ->
		diceRoller =
			roll: -> 'theDice'

		beforeEach ->
			registerPlayers 1, 2
			miaGame.currentPlayer = player1
			miaGame.setDiceRoller diceRoller
			miaGame.setBroadcastTimeout 20
			spyOn miaGame, 'currentPlayerLoses'

		it 'should inform the player about their roll', ->
			spyOn player1, 'yourRoll'
			miaGame.rollDice()
			expect(player1.yourRoll).toHaveBeenCalledWith 'theDice', jasmine.anything()

		it 'should store the actual roll', ->
			miaGame.rollDice()
			expect(miaGame.actualDice).toBe 'theDice'

		it 'should broadcast the decision to roll to all players', ->
			spyOn player1, 'playerRolls'
			spyOn player2, 'playerRolls'
			miaGame.rollDice()
			expect(player1.playerRolls).toHaveBeenCalledWith player1
			expect(player2.playerRolls).toHaveBeenCalledWith player1
			
		it 'should call announce with the announced dice', ->
			spyOn miaGame, 'announce'
			player1.yourRoll = (dice, announce) -> announce 'announcedDice'
			miaGame.rollDice()
			expect(miaGame.announce).toHaveBeenCalledWith 'announcedDice'

		it 'should make the player lose, when she does not announce within time', ->
			spyOn miaGame, 'announce'
			player1.yourRoll = (dice, announce) -> setTimeout announce, 30

			miaGame.rollDice()

			await delay 50, ->
				expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'DID_NOT_ANNOUNCE'
				expect(miaGame.announce).not.toHaveBeenCalled()

		it 'should make the player lose, when she does not announce', ->
			player1.yourRoll = (dice, announce) ->

			miaGame.rollDice()

			await delay 50, ->
				expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'DID_NOT_ANNOUNCE'

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
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'ANNOUNCED_LOSING_DICE'

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
			spyOn miaGame, 'broadcastAnnouncedDice'
			spyOn miaGame, 'broadcastActualDice'
			miaGame.actualDice = dice.create 2, 1
			miaGame.announce(dice.create 1, 2)
			expect(miaGame.broadcastAnnouncedDice).toHaveBeenCalledWith dice.create(2, 1)
			expect(miaGame.broadcastActualDice).toHaveBeenCalled()

		it 'should make everybody but the current player lose on mia', ->
			spyOn miaGame, 'everybodyButTheCurrentPlayerLoses'
			miaGame.actualDice = dice.create(2, 1)
			miaGame.announce dice.create(2, 1)
			expect(miaGame.everybodyButTheCurrentPlayerLoses).toHaveBeenCalledWith 'MIA'

		it 'should make player lose, when she announces mia wrongly', ->
			miaGame.actualDice = dice.create 2, 2
			miaGame.announce(dice.create 1, 2)
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'LIED_ABOUT_MIA'

		it 'should broadcast dice when whe announces mia wrongly', ->
			spyOn miaGame, 'broadcastAnnouncedDice'
			spyOn miaGame, 'broadcastActualDice'
			miaGame.actualDice = dice.create(3, 1)
			miaGame.announce dice.create(2, 1)
			expect(miaGame.broadcastAnnouncedDice).toHaveBeenCalledWith dice.create(2, 1)
			expect(miaGame.broadcastActualDice).toHaveBeenCalled()

		it 'should do nothing if the game is stopped', ->
			spyOn miaGame, 'nextTurn'
			miaGame.stop()
			miaGame.announce(dice.create 3, 3)
			expect(miaGame.nextTurn).not.toHaveBeenCalled()

	describe 'when player wants to see', ->
		beforeEach ->
			registerPlayers 1, 2
			spyOn miaGame, 'currentPlayerLoses'
			spyOn miaGame, 'lastPlayerLoses'

		it 'should broadcast the decision to see to all players', ->
			spyOn player1, 'playerWantsToSee'
			spyOn player2, 'playerWantsToSee'
			miaGame.currentPlayer = player1
			miaGame.showDice()
			expect(player1.playerWantsToSee).toHaveBeenCalledWith player1
			expect(player2.playerWantsToSee).toHaveBeenCalledWith player1

		it 'should broadcast actual dice', ->
			spyOn miaGame, 'broadcastActualDice'
			miaGame.actualDice = dice.create(3, 1)
			miaGame.announcedDice = dice.create(3,2)
			miaGame.showDice()
			expect(miaGame.broadcastActualDice).toHaveBeenCalled()

		it 'should make current player lose when no dice are available', ->
			miaGame.showDice()
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'SEE_BEFORE_FIRST_ROLL'
			expect(miaGame.lastPlayerLoses).not.toHaveBeenCalled()

		it 'should not try to broadcast actual dice when no dice are available', ->
			spyOn miaGame, 'broadcastActualDice'
			miaGame.showDice()
			expect(miaGame.broadcastActualDice).not.toHaveBeenCalled()

		it 'should make last player lose when actualDice are lower than announcedDice', ->
			miaGame.actualDice = dice.create 3, 1
			miaGame.announcedDice = dice.create 3, 3
			miaGame.showDice()
			expect(miaGame.currentPlayerLoses).not.toHaveBeenCalled()
			expect(miaGame.lastPlayerLoses).toHaveBeenCalledWith 'CAUGHT_BLUFFING'

		it 'should make current lose when actualDice are higher than announcedDice', ->
			miaGame.actualDice = dice.create 3, 3
			miaGame.announcedDice = dice.create 3, 1
			miaGame.showDice()
			expect(miaGame.lastPlayerLoses).not.toHaveBeenCalled()
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'SEE_FAILED'

		it 'should make current player lose when actualDice are same as announcedDice', ->
			miaGame.actualDice = dice.create 2, 3
			miaGame.announcedDice = dice.create 2, 3
			miaGame.showDice()
			expect(miaGame.currentPlayerLoses).toHaveBeenCalledWith 'SEE_FAILED'
			expect(miaGame.lastPlayerLoses).not.toHaveBeenCalled()

		it 'should do nothing if game is stopped', ->
			spyOn miaGame, 'broadcastActualDice'
			miaGame.stop()
			miaGame.showDice()
			expect(miaGame.broadcastActualDice).not.toHaveBeenCalled()

	describe 'broadcast dice', ->
		beforeEach ->
			registerPlayers 1, 2
			miaGame.currentRound.add player2
			
		it 'should tell all players about the announced dice', ->
			spyOn player1, 'announcedDiceBy'
			spyOn player2, 'announcedDiceBy'
			miaGame.currentPlayer = player2
			miaGame.broadcastAnnouncedDice 'theDice'
			expect(player1.announcedDiceBy).toHaveBeenCalledWith 'theDice', player2
			expect(player2.announcedDiceBy).toHaveBeenCalledWith 'theDice', player2

		it 'should tell all players about the actual dice', ->
			spyOn player1, 'actualDice'
			spyOn player2, 'actualDice'
			miaGame.actualDice = 'theDice'
			miaGame.broadcastActualDice()
			expect(player1.actualDice).toHaveBeenCalledWith 'theDice'
			expect(player2.actualDice).toHaveBeenCalledWith 'theDice'

	describe 'current player loses', ->
		beforeEach ->
			registerPlayers 1

		it 'should call players lose with the current player', ->
			spyOn miaGame, 'playersLose'
			miaGame.currentPlayer = player1
			miaGame.currentPlayerLoses 'theReason'
			expect(miaGame.playersLose).toHaveBeenCalledWith [player1], 'theReason'

	describe 'last player loses', ->
		beforeEach ->
			registerPlayers 1

		it 'should call players lose with the last player', ->
			spyOn miaGame, 'playersLose'
			miaGame.lastPlayer = player1
			miaGame.lastPlayerLoses 'theReason'
			expect(miaGame.playersLose).toHaveBeenCalledWith [player1], 'theReason'

	describe 'everybody but the current player loses', ->
		beforeEach ->
			registerPlayers 1, 2, 3, 4
			miaGame.currentRound.add player1
			miaGame.currentRound.add player2
			miaGame.currentRound.add player3

		it 'should call players lose with all but the current player', ->
			spyOn miaGame, 'playersLose'
			miaGame.currentPlayer = player1
			miaGame.everybodyButTheCurrentPlayerLoses 'aReason'
			expect(miaGame.playersLose).toHaveBeenCalledWith [player2, player3], 'aReason'

	describe 'players lose', ->
		beforeEach ->
			registerPlayers 1, 2, 3
			miaGame.currentRound.add player1
			miaGame.currentRound.add player2
			spyOn miaGame, 'newRound'

		it 'should decrease the score', ->
			spyOn miaGame.score, 'decreaseFor'
			miaGame.playersLose [player1, player2], 'theReason'
			expect(miaGame.score.decreaseFor).toHaveBeenCalledWith player1
			expect(miaGame.score.decreaseFor).toHaveBeenCalledWith player2
			expect(miaGame.score.decreaseFor).not.toHaveBeenCalledWith player3

		it 'should broadcast player lost to all players', ->
			spyOn player1, 'playerLost'
			spyOn player2, 'playerLost'
			spyOn player3, 'playerLost'
			miaGame.playersLose [player2], 'theReason'
			expect(player1.playerLost).toHaveBeenCalledWith [player2], 'theReason'
			expect(player2.playerLost).toHaveBeenCalledWith [player2], 'theReason'
			expect(player3.playerLost).toHaveBeenCalledWith [player2], 'theReason'

		it 'should do nothing if game is stopped', ->
			spyOn player1, 'playerLost'
			miaGame.lastPlayer = player1
			miaGame.stop()
			miaGame.playersLose [player2], 'aReason'
			expect(player1.playerLost).not.toHaveBeenCalled()

		it 'should broadcast the score', ->
			spyOn miaGame, 'broadcastScore'
			miaGame.playersLose [player1], 'aReason'
			expect(miaGame.broadcastScore).toHaveBeenCalled()

		it 'should start the next round', ->
			miaGame.playersLose [player1], 'aReason'
			expect(miaGame.newRound).toHaveBeenCalled()

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

