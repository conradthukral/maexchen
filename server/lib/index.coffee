miaServer = require './miaServer'

server = miaServer.start 9000
server.doNotStartRoundsEarly()
server.startGame()

