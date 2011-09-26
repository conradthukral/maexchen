remotePlayer = require '../lib/remotePlayer'
miaGame = require '../lib/miaGame'

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

	it 'should send message when registered successfully', ->
		player.registered()
		expect(mySpy.sendMessage).toHaveBeenCalledWith 'REGISTERED;0'

	describe 'when asked to join a round', ->

		beforeEach ->
			player.willJoinRound mySpy.callback

		it 'should send ROUND STARTING', ->
			expect(mySpy.sendMessage).toHaveBeenCalledWith 'ROUND STARTING;theToken'
		
		it 'should accept a JOIN', ->
			player.handleMessage 'JOIN', ['theToken']
			expect(mySpy.callback).toHaveBeenCalledWith true

		it 'should ignore a JOIN with the wrong token', ->
			player.handleMessage 'JOIN', ['wrongToken']
			expect(mySpy.callback).not.toHaveBeenCalled()

		it 'should ignore other messages', ->
			player.handleMessage 'ROLL', ['theToken']
			expect(mySpy.callback).not.toHaveBeenCalled()

		it 'should accept a valid message after invalid messages', ->
			player.handleMessage 'ROLL', ['theToken']
			player.handleMessage 'JOIN', ['wrongToken']
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

		it 'should ignore messages with the wrong token', ->
			player.handleMessage 'ROLL', ['wrongToken']
			expect(mySpy.callback).not.toHaveBeenCalled()

		it 'should ignore other messages', ->
			player.handleMessage 'JOIN', ['theToken']
			expect(mySpy.callback).not.toHaveBeenCalled()

		it 'should accept a valid message after invalid messages', ->
			player.handleMessage 'JOIN', ['theToken']
			player.handleMessage 'ROLL', ['wrongToken']
			player.handleMessage 'ROLL', ['theToken']
			expect(mySpy.callback).toHaveBeenCalled()


