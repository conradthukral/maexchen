dice = require '../lib/dice'

describe 'dice', ->

	describe 'equals', ->
		it 'should be true for equal dice', ->
			first = dice.create 3, 1
			second = dice.create 1, 3
			expect(first.equals second).toBeTruthy()
			expect(second.equals first).toBeTruthy()
			
		it 'should be false for different dice', ->
			first = dice.create 3, 1
			second = dice.create 2, 3
			expect(first.equals second).toBeFalsy()
			expect(first.equals null).toBeFalsy()

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

		it 'should not declare double two as mia', ->
			doubleTwo = dice.create 2, 2
			expect(doubleTwo.isMia()).toBeFalsy()

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


	describe 'string representation', ->

		it 'should be nicely formatted', ->
			thirtyOne = dice.create 1, 3
			expect("#{thirtyOne}").toEqual '3,1'

		it 'should parse its own representation', ->
			thirtyOne = dice.create 1, 3
			parsed = dice.parse thirtyOne.toString()
			expect(parsed).toEqual thirtyOne

		it 'should not parse garbage', ->
			expect(dice.parse 'garbage').toBeFalsy()

