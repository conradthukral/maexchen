exports.waitFor = (timeout, predicate) ->
    new Promise (resolve, reject) ->
        count = 0
        check = => 
            return resolve() if predicate()
            time = count++ * 5
            return reject() if time > timeout
            setTimeout check, 5
        check()

exports.delay = (timeout, func) -> 
    new Promise (resolve) ->
        setTimeout (-> resolve func() ), timeout 