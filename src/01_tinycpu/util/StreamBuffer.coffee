# Provides a file buffer connected to a filesystem stream
#

{vlog} = require 'verbosity'
{decSymbol, getSymbol} = require 'symbols'
{Events} = require 'util/events'
{Buffer} = require 'buffer'
fs = require 'fs'
keypress = require 'keypress'

if getSymbol('__WEB_APP__')
	vlog 50, 'FileBuffer skipped due to web app mode'
	return

class FileBuffer extends Buffer
	constructor: (fileDescriptor) ->
		@fd = fileDescriptor
exports.FileBuffer = FileBuffer

decSymbol 'FileBuffer', FileBuffer

module.exports = exports
