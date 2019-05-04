expireCallback = require '../lib/expireCallback'
expireCallback.setDefaultTimeout 5

mySpy = null

delay = (timeout, func) -> setTimeout(func, timeout)

describe 'The Expirer', ->
	beforeEach ->
		mySpy = callMe: ->
		spyOn mySpy, 'callMe'

	it 'should give a callback that calls the original one with arguments', ->
		expirer = expireCallback.startExpirer()
		callExpiring = expirer.makeExpiring mySpy.callMe
		expect(mySpy.callMe).not.toHaveBeenCalled()
		callExpiring 1, 2
		expect(mySpy.callMe).toHaveBeenCalledWith 1, 2

	it 'should call the callback before it expires', (done) ->
		expirer = expireCallback.startExpirer()
		callExpiring = expirer.makeExpiring(mySpy.callMe)
		
		delay 0, -> callExpiring 1, 2

		delay 0, ->
			expect(mySpy.callMe).toHaveBeenCalledWith 1, 2
			done()

	it 'should not call the callback after timeout', (done) ->
		expirer = expireCallback.startExpirer()
		callExpiring = expirer.makeExpiring(mySpy.callMe)
		setTimeout callExpiring, 10

		delay 20, ->
			expect(mySpy.callMe).not.toHaveBeenCalled()
			done()

	it 'should call the onExpire callback after timeout', (done) ->
		expirer = expireCallback.startExpirer
			onExpire: mySpy.callMe
		expirer.makeExpiring(->)

		delay 0, ->
			expect(mySpy.callMe).not.toHaveBeenCalled()
		
		delay 20, ->
			expect(mySpy.callMe).toHaveBeenCalled()
			done()

	it 'should not call onExpire when cancelExpireAction is true and callback was called', (done) ->
		expirer = expireCallback.startExpirer
			onExpire: mySpy.callMe
			cancelExpireAction: true
		callExpiring = expirer.makeExpiring(->)
		callExpiring()
		expect(mySpy.callMe).not.toHaveBeenCalled()

		delay 20, ->
			expect(mySpy.callMe).not.toHaveBeenCalled()
			done()

	it 'should call onExpire when cancelExpireAction is true and callback was not called', (done) ->
		expirer = expireCallback.startExpirer
			onExpire: mySpy.callMe
			cancelExpireAction: true
		expirer.makeExpiring(->)
		expect(mySpy.callMe).not.toHaveBeenCalled()

		delay 20, ->
			expect(mySpy.callMe).toHaveBeenCalled()
			done()

	it 'should not call onExpire when cancelExpireActions was called', (done) ->
		expirer = expireCallback.startExpirer
			onExpire: mySpy.callMe
		expirer.makeExpiring(->)
		expirer.cancelExpireActions()

		delay 20, ->
			expect(mySpy.callMe).not.toHaveBeenCalled()
			done()
