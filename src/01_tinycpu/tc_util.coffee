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

module.exports = exports