# Provides a generic buffer
#
# Buffers are used by various hardware devices such as Stdio.
#

class Buffer
	@buffer = []
	@pos = 0

	eof: () -> @pos == @buffer.length
	read: () -> val = @buffer[@pos++]; @rangecheck(); val
	write: (value) -> @_push value
	seek: (offset, from) ->
		@pos = switch from
			when SEEK_CURR  then pos + offset
			when SEEK_START then offset
			when SEEK_END   then @buffer.length + offset
		@rangecheck()
	
	rangecheck: () ->
		# If we go beyond the buffer, rewind to the start
		while @pos > @buffer.length
			@pos -= @buffer.length
		@pos

	_push: (value) -> @buffer.push value; value
	_pop: () -> @buffer.pop()

	# Read up to the end of the buffer (or max) and return as a string
	flush: (max, mapper, reducer) ->
		length = 0
		result = []
		mapper ||= String.fromCharCode
		reducer ||= (r) -> r.join ''
		while !@eof() && (if max then length++ <= max else true)
			result.push mapper(@read)
		reducer result

exports.Buffer = Buffer