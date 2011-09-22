class Dice
	constructor: (die1, die2) ->
		# die1 is the higher-valued die, die2 the lower-valued one
		[@die2, @die1] = [die1, die2].sort()

	isDouble: () ->
		@die1 == @die2

	isMia: () ->
		@die1 == 2 and @die2 = 1

	isHigherThan: (otherDice) ->
		return @valueForOrdering() > otherDice.valueForOrdering()

	valueForOrdering: () ->
		result = 10*@die1 + @die2
		result += 100 if @isDouble()
		result += 200 if @isMia()
		result

exports.create = (die1, die2) ->
	new Dice(die1, die2)

