remotePlayer = require '../lib/remotePlayer'
miaGame = require '../lib/miaGame'
dice = require '../lib/dice'

describe "remotePlayer", ->
	
	player = null
	mySpy =
		sendMessage: ->
		callback: ->

	beforeEach ->
		spyOn mySpy, 'sendMessage'
		spyOn mySpy, 'callback'
		player = remotePlayer.create 'playerName', mySpy.sendMessage
		player.generateToken = -> 'theToken'

	it 'should silently ignore messages initially', ->
		player.handleMessage 'JOIN', 'token'
		expect(mySpy.sendMessage).not.toHaveBeenCalled()

	describe 'when asked to join a round', ->

		beforeEach ->
			player.willJoinRound mySpy.callback

		it 'should send ROUND STARTING', ->
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'ROUND STARTING;theToken'
		
		it 'should accept a JOIN', ->
			player.handleMessage 'JOIN', ['theToken']
			expect(mySpy.callback).toHaveBeenCalledWith true

		it 'should ignore invalid messages ', ->
			player.handleMessage 'JOIN', ['wrongToken']
			player.handleMessage 'ROLL', ['theToken']
			expect(mySpy.callback).not.toHaveBeenCalled()

			player.handleMessage 'JOIN', ['theToken']
			expect(mySpy.callback).toHaveBeenCalled()

	describe 'when asked for a turn', ->

		beforeEach ->
			player.yourTurn mySpy.callback

		it 'should send YOUR TURN', ->
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'YOUR TURN;theToken'

		it 'should accept a ROLL', ->
			player.handleMessage 'ROLL', ['theToken']
			expect(mySpy.callback).toHaveBeenCalledWith miaGame.Messages.ROLL

		it 'should accept a SEE', ->
			player.handleMessage 'SEE', ['theToken']
			expect(mySpy.callback).toHaveBeenCalledWith miaGame.Messages.SEE

		it 'should ignore invalid messages', ->
			player.handleMessage 'JOIN', ['theToken']
			player.handleMessage 'ROLL', ['wrongToken']
			expect(mySpy.callback).not.toHaveBeenCalled()

			player.handleMessage 'ROLL', ['theToken']
			expect(mySpy.callback).toHaveBeenCalled()

	describe 'after rolling dice', ->
		
		beforeEach ->
			player.yourRoll 'theDice', mySpy.callback

		it 'should send ROLLED', ->
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'ROLLED;theDice;theToken'

		it 'should accept ANNOUNCE', ->
			player.handleMessage 'ANNOUNCE', ['3,1', 'theToken']
			expect(mySpy.callback).toHaveBeenCalledWith dice.create(3,1)

		it 'should ignore invalid messages', ->
			player.handleMessage 'ANNOUNCE', ['3,1', 'wrongToken']
			player.handleMessage 'ANNOUNCE', ['invalidDice', 'theToken']
			player.handleMessage 'JOIN', ['theToken']
			expect(mySpy.callback).not.toHaveBeenCalled()

			player.handleMessage 'ANNOUNCE', ['2,1', 'theToken']
			expect(mySpy.callback).toHaveBeenCalled()

	describe 'when round is canceled', ->

		it 'should send ROUND CANCELED', ->
			player.roundCanceled 'theReason'
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'ROUND CANCELED;theReason'

		it 'should ignore previously valid messages', ->
			player.yourRoll 'theDice', mySpy.callback
			player.roundCanceled 'theReason'
			player.handleMessage 'ANNOUNCE', ['2,1', 'theToken']

			expect(mySpy.callback).not.toHaveBeenCalled()

	describe 'other notifications', ->

		it 'should send ANNOUNCED notifications', ->
			otherPlayer = name: 'theOtherPlayer'
			player.announcedDiceBy 'theDice', otherPlayer
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'ANNOUNCED;theOtherPlayer;theDice'

		it 'should send ROUND STARTED notifications', ->
			player1 = name: 'player1'
			player2 = name: 'player2'
			player.roundStarted 23, [player1, player2]
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'ROUND STARTED;23;player1,player2'

		it 'should send PLAYER ROLLS notifications', ->
			rollingPlayer = name: 'rollingPlayer'
			player.playerRolls rollingPlayer
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'PLAYER ROLLS;rollingPlayer'

		it 'should send PLAYER WANTS TO SEE notifications', ->
			seeingPlayer = name: 'seeingPlayer'
			player.playerWantsToSee seeingPlayer
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'PLAYER WANTS TO SEE;seeingPlayer'

		it 'should send ACTUAL DICE notifications', ->
			player.actualDice dice.create(3, 2)
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'ACTUAL DICE;3,2'

		it 'should send PLAYER LOST notifications', ->
			losingPlayer1 = name: 'player1'
			losingPlayer2 = name: 'player2'
			player.playerLost [losingPlayer1, losingPlayer2], 'theReason'
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'PLAYER LOST;player1,player2;theReason'

		it 'should send SCORE notifications', ->
			scores = player1: 23, player2: 42
			player.currentScore scores
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'SCORE;player1:23,player2:42'

		it 'should send REGISTERED notifications', ->
			player.registered()
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'REGISTERED'

		it 'should send REJECTED notifications', ->
			player.registrationRejected 'forAReason'
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'REJECTED;forAReason'

