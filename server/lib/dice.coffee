class Dice
	constructor: (die1, die2) ->
		# die1 is the higher-valued die, die2 the lower-valued one
		[@die2, @die1] = [die1, die2].sort()

	isDouble: () ->
		@die1 == @die2

	isMia: () ->
		@die1 == 2 and @die2 = 1

	isHigherThan: (otherDice) ->
		return this.valueForOrdering() > otherDice.valueForOrdering()

	valueForOrdering: () ->
		result = 10*@die1 + @die2
		result += 100 if this.isDouble()
		result += 200 if this.isMia()
		result

rollOneDie = ->
	Math.floor(Math.random()*6) + 1

exports.create = (die1, die2) ->
	new Dice(die1, die2)

exports.roll = () ->
	new Dice(rollOneDie(), rollOneDie())
