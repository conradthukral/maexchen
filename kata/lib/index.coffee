dgram = require 'dgram'
trial = require './trial'

runningTrials = {}
socket = null

createSender = (host, port) ->
	(message) ->
		console.log "Sending #{message} to #{host}"
		buffer = new Buffer(message)
		socket.send buffer, 0, buffer.length, port, host

findTrialFor = (host) -> runningTrials[host]

createTrialFor = (host, port) ->
	result = trial.create createSender(host, port)
	runningTrials[host] = result

removeTrialFor = (host) ->
	runningTrials[host] = null

handleMessage = (messageBuffer, rinfo) =>
	message = messageBuffer.toString()
	console.log "Received #{message} from #{rinfo.address}"
	if message == 'START'
		currentTrial = createTrialFor rinfo.address, rinfo.port
		currentTrial.start()
	else
		currentTrial = findTrialFor rinfo.address
		currentTrial?.handleMessage message
		removeTrialFor rinfo.address if currentTrial?.isCompleted()

socket = dgram.createSocket 'udp4', handleMessage
socket.bind 9001

console.log "Kata server started on port 9001"
