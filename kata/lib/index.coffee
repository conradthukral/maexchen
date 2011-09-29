dgram = require 'dgram'
trial = require './trial'

runningTrials = {}
socket = null

createSender = (host, port) ->
	(message) ->
		console.log "Sending #{message} to #{host}"
		buffer = new Buffer(message)
		socket.send buffer, 0, buffer.length, port, host

findOrCreateTrialFor = (host, port) ->
	result = runningTrials[host]
	unless result
		result = trial.create createSender(host, port)
		runningTrials[host] = result
	result

removeTrialFor = (host) ->
	runningTrials[host] = null

handleMessage = (message, rinfo) =>
	console.log "Received #{message.toString()} from #{rinfo.address}"
	currentTrial = findOrCreateTrialFor rinfo.address, rinfo.port
	currentTrial.handleMessage message.toString()
	removeTrialFor rinfo.address if currentTrial.isCompleted()


socket = dgram.createSocket 'udp4', handleMessage
socket.bind 9001
