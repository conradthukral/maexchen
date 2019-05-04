diceRoller = require '../lib/diceRoller'

describe 'diceRoller', ->

	beforeEach ->
		jasmine.addMatchers
			toBeADieValue: ->
				compare: (actual) ->
					pass = Math.floor(actual) == actual && 1 <= actual <= 6
					result = 
						pass: pass
						message: "expected #{actual}#{' not' unless pass} to be a valid D6 value"

	it 'should generate valid die values', ->
		rolled = diceRoller.roll()
		expect(rolled.die1).toBeADieValue()
		expect(rolled.die2).toBeADieValue()
