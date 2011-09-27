score = require '../lib/score'

describe 'Score', ->

	currentScore = null
	player1 = null
	player2 = null

	beforeEach ->
		currentScore = score.create()
		player1 = name: 'playerName1'
		player2 = name: 'playerName2'

	it 'should be zero initially', ->
		expect(currentScore.of player1).toBe 0
		expect(currentScore.of player2).toBe 0
	
	it 'should increment scores for individual players', ->
		currentScore.increaseFor player1
		expect(currentScore.of player1).toBe 1

		currentScore.increaseFor player1
		expect(currentScore.of player1).toBe 2

	it 'should not increment scores for other players', ->
		currentScore.increaseFor player1
		expect(currentScore.of player2).toBe 0

	it 'should decrease scores for individual players', ->
		currentScore.increaseFor player1
		currentScore.decreaseFor player1
		expect(currentScore.of player1).toBe 0
	
	it 'should collect all scores', ->
		currentScore.increaseFor player1
		currentScore.increaseFor player2
		currentScore.increaseFor player2

		expect(currentScore.all()).toEqual playerName1: 1, playerName2: 2
