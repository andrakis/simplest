# Provides a generic buffer
#
# Buffers are used by various hardware devices such as Stdio.
#

{vlog} = require('verbosity')

class Buffer
	constructor: () ->
		@buffer = []
		@pos = 0

	eof: () -> @pos == @buffer.length
	read: () ->
		val = @buffer[@pos++]
		vlog(50, "Buffer.read() = ", val)
		@rangecheck()
		val
	write: (value) ->
		vlog(50, "Buffer.write(", value, ")")
		@_push value
	seek: (offset, from) ->
		@pos = switch from
			when SEEK_CURR  then pos + offset
			when SEEK_START then offset
			when SEEK_END   then @buffer.length + offset
		@rangecheck()
	
	rangecheck: () ->
		# If we go beyond the buffer, rewind to the start
		while @pos > @buffer.length
			vlog(70, "Adjusting @pos from ", @pos, " to ", @pos - @buffer.length)
			@pos -= @buffer.length
		@pos

	_push: (value) -> vlog(70, "This is ", @); @buffer.push value; value
	_pop: () -> @buffer.pop()

	# Read up to the end of the buffer (or max) and return as a string
	flush: (max, mapper, reducer) ->
		length = 0
		result = []
		mapper ||= String.fromCharCode
		reducer ||= (r) -> r.join ''
		while !@eof() && (if max then length++ <= max else true)
			v = mapper(@read())
			vlog(70, "Buffer.flush: got ", v)
			result.push v
		reducer result

exports.Buffer = Buffer
