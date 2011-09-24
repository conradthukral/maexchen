defaultTimeout = 200

startExpirer = (conf = {}) ->
	{timeout, onExpire, cancelExpireAction} = conf
	timeout ?= defaultTimeout
	onExpire ?= ->
	cancelExpireAction ?= false

	preventOnExpireAction = false
	expired = false

	callOnExpire = ->
		onExpire() unless preventOnExpireAction
		expired = true

	setTimeout callOnExpire, timeout

	makeExpiring = (callback) ->
		(arg...) ->
			preventOnExpireAction = cancelExpireAction
			callback(arg...) unless expired

	makeExpiring: makeExpiring

exports.startExpirer = startExpirer
exports.setDefaultTimeout = (timeout = 200) -> defaultTimeout = timeout
