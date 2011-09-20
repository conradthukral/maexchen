mia = require '../lib/miaGame'

class PlayerStub
	constructor: (@answer) ->
	answerQuestion: (question) ->
		question(@answer)

describe 'broadcast', ->
	players = player1 = player2 = answers = null

	beforeEach ->
		player1 = new PlayerStub true
		player2 = new PlayerStub true
		players = new mia.classes.PlayerList
		players.add player1
		players.add player2
		answers = []

	it 'should not block, when no answer is given', ->
		runs ->
			players.each (player) ->
				player.answerQuestion (answer) ->
					answers.push player if answer
			expect(answers.length).toBe 0
		waits 0
		runs ->
			expect(answers.length).toBe 2
			expect(answers[0]).toBe player1
			expect(answers[1]).toBe player2
