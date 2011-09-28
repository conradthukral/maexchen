defaultTimeout = 200

startExpirer = (conf = {}) ->
	{timeout, onExpire, cancelExpireAction} = conf
	timeout ?= defaultTimeout
	onExpire ?= ->
	cancelExpireAction ?= false

	expired = false

	callOnExpire = ->
		onExpire()
		expired = true

	setTimeout callOnExpire, timeout

	makeExpiring = (callback) ->
		(arg...) ->
			cancelExpireActions() if cancelExpireAction
			callback(arg...) unless expired

	cancelExpireActions = ->
		onExpire = ->

	expirer =
		makeExpiring: makeExpiring
		cancelExpireActions: cancelExpireActions

exports.startExpirer = startExpirer
exports.setDefaultTimeout = (timeout = 200) -> defaultTimeout = timeout
