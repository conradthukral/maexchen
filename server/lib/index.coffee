miaServer = require './miaServer'

console.log "arguments: [port=9000] [startRoundsEarly=false] [answerTimeout=250ms] [initialDelay=0ms]"

port = parseInt process.argv[2]
port = 9000 if isNaN port

startRoundsEarly = process.argv[3] == 'true'

answerTimeout = parseInt process.argv[4]
answerTimeout = 250 if isNaN answerTimeout

initialDelay = parseInt process.argv[5]
initialDelay = 0 if isNaN initialDelay

server = miaServer.start port, answerTimeout
server.doNotStartRoundsEarly() unless startRoundsEarly

setTimeout (-> server.startGame()), initialDelay

