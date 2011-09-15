dice = require '../lib/dice'

describe 'dice', ->

	describe 'roll', ->

		beforeEach ->
			this.addMatchers
				toBeADieValue: ->
					Math.floor(this.actual) == this.actual && 1 <= this.actual <= 6

		it 'should generate valid die values', ->
			rolled = dice.roll()
			expect(rolled.die1).toBeADieValue()
			expect(rolled.die2).toBeADieValue()

	describe 'isHigherThan', ->

		it 'should not be reflexive', ->
			thirtyOne = dice.create 3, 1
			expect(thirtyOne.isHigherThan(thirtyOne)).toBeFalsy()

		it 'should order simple rolls correctly', ->
			thirtyOne = dice.create 3, 1
			fourtyOne = dice.create 4, 1
			fourtyTwo = dice.create 4, 2
			expectDiceOrder thirtyOne, fourtyOne
			expectDiceOrder fourtyOne, fourtyTwo
			expectDiceOrder thirtyOne, fourtyTwo

		it 'should order doubles correctly', ->
			sixtyFive = dice.create 6, 5
			doubleOne = dice.create 1, 1
			doubleSix = dice.create 6, 6
			expectDiceOrder sixtyFive, doubleOne
			expectDiceOrder doubleOne, doubleSix

		it 'should order mia correctly', ->
			mia = dice.create 2, 1
			doubleSix = dice.create 6, 6
			expectDiceOrder doubleSix, mia

		it 'should not care about the order of the dice', ->
			reverseSixtyOne = dice.create 1, 6
			thirtyOne = dice.create 3, 1
			expectDiceOrder thirtyOne, reverseSixtyOne

		expectDiceOrder = (lower, higher) ->
			expect(higher.isHigherThan(lower)).toBeTruthy()
			expect(lower.isHigherThan(higher)).toBeFalsy()


