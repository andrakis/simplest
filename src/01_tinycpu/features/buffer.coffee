# Provides a generic buffer
#
# Buffers are used by various hardware devices such as Stdio.
#

{vlog} = require('verbosity')
{decSymbol} = require('symbols')
{clone, SuperClass} = require 'tc_util'
{Events} = require 'util/events'

class Buffer extends SuperClass
	@include Events

	constructor: () ->
		Events.call @
		@event 'read', "Whenever content is checked for and read from the buffer"
		@event 'write', "Whenever content is written to the buffer"
		@event 'switch', "Whenever the buffer is switched"
		@event 'flush', "Whenever the buffer is flushed"
		@event 'flush_noclear', "Called internally by flush, or by flush_noclear"
		@reset()

	eof: () -> @pos == @buffer.length
	feof: () -> @eof()
	read: () ->
		value = @buffer[@pos++]
		vlog(50, "Buffer.read() = ", value)
		@_rangecheck()
		@fire 'read', value
		value
	write: (value) ->
		vlog(50, "Buffer.write(", value, ")")
		@_push value
		@fire 'write', value
		value
	seek: (offset, from) ->
		@pos = switch from
			when SEEK_CURR  then pos + offset
			when SEEK_START then offset
			when SEEK_END   then @buffer.length + offset
		@_rangecheck()

	# Read up to the end of the buffer (or max) and return as a string.
	# Does not clear the buffer
	flush_noclear: (max, mapper, reducer) ->
		length = 0
		result = []
		mapper ||= String.fromCharCode
		reducer ||= (r) -> r.join ''
		while !@eof() && (if max then length++ <= max else true)
			v = mapper(@read())
			vlog(70, "Buffer.flush: got ", v)
			result.push v
		final = reducer result
		@fire 'flush_noclear', final
		final
	# Read up to the end of the buffer (or max) and return as a string.
	# Clears the buffer
	flush: (max, mapper, reducer) ->
		result = @flush_noclear max, mapper, reducer
		@reset
		result
	
	# Clear and reset the buffer
	reset: () ->
		@buffer = []
		@pos = 0
	
	on_read : (callback) -> @on 'read' , callback
	on_write: (callback) -> @on 'write', callback
	on_flush: (callback) -> @on 'flush', callback
	on_flush_noclear: (callback) -> @on 'flush_noclear', callback
	on_switch: (callback) -> @on 'switch', callback

	# Switch to a new buffer. By default, copies contents to target
	# buffer.
	switch: (dest, supress_copy) ->
		vlog 50, "Switching buffer to", dest
		if !supress_copy
			vlog 50, " Copying buffer contents"
			dest.reset()
			dest.buffer = clone @buffer
			dest.pos = @pos
		dest

	_rangecheck: () ->
		# If we go beyond the buffer, rewind to the start
		while @pos > @buffer.length
			vlog(70, "Adjusting @pos from ", @pos, " to ", @pos - @buffer.length)
			@pos -= @buffer.length
		@pos

	_push: (value) -> @buffer.push value; value
	_pop: () -> @buffer.pop()

decSymbol 'Buffer', Buffer
exports.Buffer = Buffer

module.exports = exports

decSymbol 'Buffer.exports', exports
