diceRoller = require '../lib/diceRoller'

describe 'diceRoller', ->

	beforeEach ->
		this.addMatchers
			toBeADieValue: ->
				Math.floor(this.actual) == this.actual && 1 <= this.actual <= 6

	it 'should generate valid die values', ->
		rolled = diceRoller.roll()
		expect(rolled.die1).toBeADieValue()
		expect(rolled.die2).toBeADieValue()

