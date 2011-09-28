miaServer = require '../lib/miaServer'

describe 'mia server', ->

	server = null
	player =
		name: 'theName'
		remoteHost: 'theHost'
		registered: ->
		registrationRejected: ->

	beforeEach ->
		server = miaServer.start()
		spyOn player, 'registered'
		spyOn player, 'registrationRejected'
		spyOn server.game, 'registerPlayer'
		spyOn(server, 'createPlayer').andReturn player

	afterEach ->
		server.shutDown()
	
	it 'should accept registrations', ->
		server.handleMessage 'REGISTER', ['theName'], 'theHost', 'thePort'
		expect(server.game.registerPlayer).toHaveBeenCalled()
		expect(player.registered).toHaveBeenCalled()

	it 'should accept an updated registration from the same remote host', ->
		server.handleMessage 'REGISTER', ['theName'], 'theHost', 'theOldPort'
		server.handleMessage 'REGISTER', ['theName'], 'theHost', 'theNewPort'
		expect(server.game.registerPlayer.callCount).toBe 2
		expect(player.registered).toHaveBeenCalled()
		expect(player.registrationRejected).not.toHaveBeenCalled()

	it 'should reject an updated registration from the a different remote host', ->
		server.handleMessage 'REGISTER', ['theName'], 'theOldHost', 'thePort'
		server.handleMessage 'REGISTER', ['theName'], 'theNewHost', 'thePort'
		expect(server.game.registerPlayer.callCount).toBe 1
		expect(player.registrationRejected).toHaveBeenCalled()
		expect(player.registered.callCount).toBe 1

