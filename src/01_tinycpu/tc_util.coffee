# TinyCPU Util functions
#

var_dump = undefined

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
	#return "undefined"  if obj == undefined
	#return exports.var_dump obj  if typeof obj == 'object'
	#return obj.toString()  if obj.toString?
	return obj  if typeof obj == 'string'
	return obj  if typeof obj == 'number'
	if var_dump?
		return var_dump obj
	{var_dump} = require 'util/var_dump'
	var_dump obj

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

exports.removeArrayItem = (array, item) ->
	index = array.indexOf item
	return array  unless index > -1

	array.splice index, 1
	array

module.exports = exports
