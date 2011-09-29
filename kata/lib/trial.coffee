uuid = require 'node-uuid'

generateToken = -> uuid()

randomInt = (max) ->
	Math.floor(Math.random() * max) + 1

addNumbers = (numbers) ->
	result = 0
	result += number for number in numbers
	result

generateQuestionAndAnswer = (op, numbers, result) ->
	token = generateToken()
	question = "#{op}:#{token}:#{numbers.join ':'}"
	answer = "#{token}:#{result}"
	[question, answer]

generateAdd = (numbers) ->
	result = addNumbers numbers
	generateQuestionAndAnswer 'ADD', numbers, result

generateSubtract = (numbers) ->
	result = randomInt(100)
	numbers[0] = addNumbers(numbers[1..]) + result
	generateQuestionAndAnswer 'SUBTRACT', numbers, result

generateMultiply = (numbers) ->
	result = 1
	result *= number for number in numbers
	generateQuestionAndAnswer 'MULTIPLY', numbers, result

generators = [generateAdd, generateSubtract, generateMultiply]

class Trial
	constructor: (@sendMessage) ->
		@right = @wrong = 0

	start: ->
		@sendQuestion()

	handleMessage: (message) ->
		if message == @expectedMessage
			console.log 'CORRECT'
			@right++
		else
			console.log "WRONG. EXPECTED #{@expectedMessage}"
			@wrong++
		if @isCompleted()
			@sendResults()
		else
			@sendQuestion()

	sendResults: ->
		if @wrong == 0
			@sendMessage 'ALL CORRECT'
		else
			@sendMessage "#{@wrong} WRONG, #{@right} CORRECT"

	sendQuestion: ->
		[question, @expectedMessage] = @generateQuestionAndAnswer()
		@sendMessage question

	generateQuestionAndAnswer: ->
		numbersCount = 1 + randomInt(4)
		numbers = (randomInt(100) for index in [1..numbersCount])
		opIndex = randomInt generators.length
		generator = generators[opIndex-1]
		generator numbers

	isCompleted: ->
		@right + @wrong == 5


exports.create = (sendMessage) -> new Trial(sendMessage)

