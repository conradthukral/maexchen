expireCallback = require '../lib/expireCallback'
expireCallback.setDefaultTimeout 5

mySpy = null

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

	it 'should call the callback before it expires', ->
		runs ->
			expirer = expireCallback.startExpirer()
			callExpiring = expirer.makeExpiring(mySpy.callMe)
			setTimeout (-> callExpiring 1, 2), 0
		waits 0
		runs ->
			expect(mySpy.callMe).toHaveBeenCalledWith 1, 2

	it 'should not call the callback after timeout', ->
		runs ->
			expirer = expireCallback.startExpirer()
			callExpiring = expirer.makeExpiring(mySpy.callMe)
			setTimeout callExpiring, 10
		waits 20
		runs ->
			expect(mySpy.callMe).not.toHaveBeenCalled()

	it 'should call the onExpire callback after timeout', ->
		runs ->
			expirer = expireCallback.startExpirer
				onExpire: mySpy.callMe
			expirer.makeExpiring(->)
		waits 0
		runs ->
			expect(mySpy.callMe).not.toHaveBeenCalled()
		waits 20
		runs ->
			expect(mySpy.callMe).toHaveBeenCalled()

	it 'should not call onExpire when cancelExpireAction is true and callback was called', ->
		runs ->
			expirer = expireCallback.startExpirer
				onExpire: mySpy.callMe
				cancelExpireAction: true
			callExpiring = expirer.makeExpiring(->)
			callExpiring()
			expect(mySpy.callMe).not.toHaveBeenCalled()
		waits 20
		runs ->
			expect(mySpy.callMe).not.toHaveBeenCalled()

	it 'should call onExpire when cancelExpireAction is true and callback was not called', ->
		runs ->
			expirer = expireCallback.startExpirer
				onExpire: mySpy.callMe
				cancelExpireAction: true
			expirer.makeExpiring(->)
			expect(mySpy.callMe).not.toHaveBeenCalled()
		waits 20
		runs ->
			expect(mySpy.callMe).toHaveBeenCalled()

	it 'should not call onExpire when cancelExpireActions was called', ->
		runs ->
			expirer = expireCallback.startExpirer
				onExpire: mySpy.callMe
			expirer.makeExpiring(->)
			expirer.cancelExpireActions()
		waits 20
		runs ->
			expect(mySpy.callMe).not.toHaveBeenCalled()
