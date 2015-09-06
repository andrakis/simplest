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
			value = "'#{value}'"
		else if typeof value == 'object'
			if value instanceof Array
				value = "[ #{value} ]"
			else
				ood = exports.DumpObjectFlat(value)
				value = "{ #{ood.dump} }"
		result += "'#{property}' : #{value}, "
		len++
	od.dump = result.replace(/, $/, '')
	od.len = len
	od

moduleKeywords = ['included', 'extended']

class SuperClass
	@include: (obj, extendedModuleKeywords) ->
		throw('include(obj) requires obj') unless obj
		if typeof obj == 'string'
			obj = require obj
		extendedModuleKeywords = extendedModuleKeywords || []
		for key, value of obj.prototype when (key not in moduleKeywords and key not in extendedModuleKeywords)
			@::[key] = value
		included = obj.included
		included.apply(this) if included
		@
exports.SuperClass = SuperClass

module.exports = exports
