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
		spyOn server.game, 'registerSpectator'
		spyOn(server, 'createPlayer').andReturn player

	afterEach ->
		server.shutDown()
	
	expectNameToBeRejected = (name) ->
		server.handleMessage 'REGISTER', [name], 'theHost', 'thePort'
		expect(player.registrationRejected).toHaveBeenCalledWith 'INVALID_NAME'
		expect(server.game.registerPlayer).not.toHaveBeenCalled()
		expect(player.registered).not.toHaveBeenCalled()

	it 'should accept registrations', ->
		server.handleMessage 'REGISTER', ['theName'], 'theHost', 'thePort'
		expect(server.game.registerPlayer).toHaveBeenCalled()
		expect(player.registered).toHaveBeenCalled()

	it 'should accept spectator registrations', ->
		server.handleMessage 'REGISTER_SPECTATOR', ['theName'], 'theHost', 'thePort'
		expect(server.game.registerSpectator).toHaveBeenCalled()
		expect(player.registered).toHaveBeenCalled()
	
	it 'should reject registrations with invalid player names', ->
		expectNameToBeRejected ''
		expectNameToBeRejected 'nameWithSemicolon;'
		expectNameToBeRejected 'white space'
		expectNameToBeRejected 'nameWithComma,'
		expectNameToBeRejected 'nameWithColon:'
		expectNameToBeRejected 'nameWhichIsWayTooLong'

	it 'should accept spectator registrations', ->
		server.handleMessage 'REGISTER_SPECTATOR', ['theName'], 'theHost', 'thePort'
		expect(server.game.registerSpectator).toHaveBeenCalled()
		expect(player.registered).toHaveBeenCalled()

	it 'should accept an updated registration from the same remote host', ->
		server.handleMessage 'REGISTER', ['theName'], {host: 'theHost', port: 'theOldPort', id: 'theHost:theOldPort'}
		server.handleMessage 'REGISTER', ['theName'], {host: 'theHost', port: 'theNewPort', id: 'theHost:theNewPort'}
		expect(server.game.registerPlayer.callCount).toBe 2
		expect(player.registered).toHaveBeenCalled()
		expect(player.registrationRejected).not.toHaveBeenCalled()

	it 'should reject an updated registration from the a different remote host', ->
		server.handleMessage 'REGISTER', ['theName'], 'theOldHost', 'thePort'
		server.handleMessage 'REGISTER', ['theName'], 'theNewHost', 'thePort'
		expect(server.game.registerPlayer.callCount).toBe 1
		expect(player.registrationRejected).toHaveBeenCalledWith 'NAME_ALREADY_TAKEN'
		expect(player.registered.callCount).toBe 1

	it 'should allow to configure whether the game starts rounds early', ->
		spyOn server.game, 'doNotStartRoundsEarly'
		server.doNotStartRoundsEarly()
		expect(server.game.doNotStartRoundsEarly).toHaveBeenCalled()

