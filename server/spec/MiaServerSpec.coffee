miaServer = require '../lib/miaServer'

describe 'mia server', ->

	game =
		registerPlayer: ->
		registerSpectator: ->
		stop: ->

	server = connection = null
	player =
		name: 'theName'
		remoteHost: 'theHost'
		registered: ->
		registrationRejected: ->

	beforeEach ->
		server = miaServer.start game
		connection =
			host: 'theHost'
			id: 'theHost:thePort'

		spyOn player, 'registered'
		spyOn player, 'registrationRejected'
		spyOn game, 'registerPlayer'
		spyOn game, 'registerSpectator'
		spyOn(server, 'createPlayer').andReturn player

	afterEach ->
		server.shutDown()
	
	expectNameToBeRejected = (name) ->
		server.handleMessage 'REGISTER', [name], connection
		expect(player.registrationRejected).toHaveBeenCalledWith 'INVALID_NAME'
		expect(server.game.registerPlayer).not.toHaveBeenCalled()
		expect(player.registered).not.toHaveBeenCalled()

	it 'should accept registrations', ->
		server.handleMessage 'REGISTER', ['theName'], connection
		expect(game.registerPlayer).toHaveBeenCalled()
		expect(player.registered).toHaveBeenCalled()

	it 'should accept spectator registrations', ->
		server.handleMessage 'REGISTER_SPECTATOR', ['theName'], connection
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
		server.handleMessage 'REGISTER_SPECTATOR', ['theName'], connection
		expect(server.game.registerSpectator).toHaveBeenCalled()
		expect(player.registered).toHaveBeenCalled()

	it 'should accept an updated registration from the same remote host', ->
		theNewConnection = belongsTo: ->
		spyOn(theNewConnection, 'belongsTo').andReturn true
		server.handleMessage 'REGISTER', ['theName'], connection
		server.handleMessage 'REGISTER', ['theName'], theNewConnection
		expect(theNewConnection.belongsTo).toHaveBeenCalledWith player
		expect(server.game.registerPlayer.callCount).toBe 2
		expect(player.registered).toHaveBeenCalled()
		expect(player.registrationRejected).not.toHaveBeenCalled()

	it 'should reject an updated registration from the a different remote host', ->
		theNewConnection = belongsTo: ->
		spyOn(theNewConnection, 'belongsTo').andReturn false
		server.handleMessage 'REGISTER', ['theName'], connection
		server.handleMessage 'REGISTER', ['theName'], theNewConnection
		expect(theNewConnection.belongsTo).toHaveBeenCalledWith player
		expect(server.game.registerPlayer.callCount).toBe 1
		expect(player.registrationRejected).toHaveBeenCalledWith 'NAME_ALREADY_TAKEN'
		expect(player.registered.callCount).toBe 1

