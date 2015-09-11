var_dump = (obj) ->
	cache = []
	result = JSON.stringify(obj, (key, value) ->
		if typeof value == 'object' and value != null
			if cache.indexOf(value) != -1
				# Circular reference found, discard key
				return
			# Store value in our collection
			cache.push value
		value
	)
	cache = null # Enable garbage collection
	result

exports.var_dump = var_dump

module.exports = exports

