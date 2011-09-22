dice = require './dice'

rollOneDie = ->
	Math.floor(Math.random()*6) + 1

exports.roll = () ->
	dice.create rollOneDie(), rollOneDie()
