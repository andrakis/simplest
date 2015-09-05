# TinyCPU Util functions
#

exports.charCode = (S) -> ("" + S).charCodeAt(0)

clone = (obj) ->
	return obj  if obj is null or typeof (obj) isnt "object"
	temp = new obj.constructor()
	for key of obj
		temp[key] = clone(obj[key])
	temp
exports.clone = clone

exports.StackTrace = () ->
	err = new Error
	err.stack

exports.DumpObjectFlat = (obj) ->
	od = new Object
	result = ''
	len = 0
	for property of obj
		value = obj[property]
		if typeof value == 'string'
			console.log 'type is string'
			value = '\'' + value + '\''
		else if typeof value == 'object'
			console.log 'value is object'
			if value instanceof Array
				value = '[ ' + value + ' ]'
			else
				ood = exports.DumpObjectFlat(value)
				value = '{ ' + ood.dump + ' }'
		result += '\'' + property + '\' : ' + value + ', '
		len++
	od.dump = result.replace(/, $/, '')
	od.len = len
	od

module.exports = exports
