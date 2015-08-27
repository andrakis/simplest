# Standard IO feature for TinyCPU
#
# It has the following features:
#   channel select (stdin, stdout, stderr, flush current channel)
#   eof
#   seek
#   read
#   write
# To use it,
#   select your channel: add abs0, STDIO_OUT, STDIO_CHANNEL
#   write your value: add abs0, 'H', STDIO_WRITE
#   select stdin: add abs0, STDIO_IN, STDIO_CHANNEL
#   check for eof:
#     add STDIO_FEOF, 0, r1    # Observe feof value
#     add eq0, 0, cp           # Jump + 3 if eof, + 0 if not
#     #jump not_eof
#     #jump is_eof
#     not_eof: #return
#     is_eof: #return
#   fseek to end - 1:
#     add abs0, SEEK_END, STDIO_FSEEK_FROM
#     add abs0, -1, STDIO_FSEEK
#   flush:
#     add abs0, STDIO_FLUSH, STDIO_CHANNEL    # STDIO_CHANNEL will be unchanged

feature = require('features/feature')
dma = require('features/dma')
{Buffer} = require('features/buffer')
{vlog} = require('verbosity')

DMA = dma[feature.FEATURE_CLASS]

FEATURE_STDIO = 'stdio'

STDIO_MAGIC_MAGIC = 0xDEADBEEF01

# Memory ranges
STDIO_MAGIC   = -4
STDIO_CHANNEL = -5
STDIO_FEOF    = -6
STDIO_FSEEK   = -7
STDIO_FSEEK_FROM = -8
STDIO_READ    = -9
STDIO_WRITE   = -10
RANGE = [-10, -4]

STDIO_IN = 0
STDIO_OUT = 1
STDIO_ERR = 2
STDIO_FLUSH = 11

SEEK_CURR = 0
SEEK_START = 1
SEEK_END = 2

class Stdio extends DMA
	constructor: (flush_callback) ->
		@buffer_stdin = new Buffer
		@buffer_stdout = new Buffer
		@buffer_stderr = new Buffer
		@buffers = [@buffer_stdin, @buffer_stdout, @buffer_stderr]
		@buffer_index = 0
		@buffer = @buffers[@buffer_index]
		@fseek_from = SEEK_CURR
		@flush_callback = flush_callback
		super
			name: "standard io"
			rangeStart: RANGE[0]
			rangeEnd: RANGE[1]
	
	dma_read: (loc, cpu) ->
		result = switch loc
			when STDIO_MAGIC   then STDIO_MAGIC_MAGIC
			when STDIO_CHANNEL then @buffer_index
			when STDIO_FEOF    then @buffer.feof()
			when STDIO_FSEEK   then 0 # not supported
			when STDIO_FSEEK_FROM then @fseek_from
			when STDIO_READ    then @buffer.read()
			when STDIO_WRITE   then 0 # not supported
		vlog(70, "io.dma_read(", loc, ")")
		result
	
	dma_write: (loc, value, cpu) ->
		result = switch loc
			when STDIO_MAGIC   then 0 # not supported
			when STDIO_CHANNEL then @switch_buffer value
			when STDIO_FEOF    then 0 # not supported
			when STDIO_FSEEK
				vlog(20, "STDIO.fseek(", value, ", ", @fseek_from, ")")
				@buffer.fseek value, @fseek_from
			when STDIO_FSEEK_FROM
				vlog(20, "STDIO.fseek_from(", value, ")")
				@fseek_from = value
			when STDIO_READ    then 0 # not supported
			when STDIO_WRITE
				vlog(20, "STDIO.write(", value, ")")
				@buffer.write value
		vlog(70, "io.dma_write(", loc, ",", value, ")")
		result
	
	switch_buffer: (buffer) ->
		if buffer >= 0 && buffer < @buffers.length
			@buffer = @buffers[@buffer_index = buffer]
			vlog(30, "STDIO.switch_buffer(", buffer, ")")
			buffer
		else if buffer == STDIO_FLUSH
			@handle_flush()
		else
			throw "stdio: switch_buffer(#{buffer}): invalid buffer"
	
	handle_flush: () ->
		vlog(50, "STDIO.flush(), calling callback: ", @flush_callback)
		@flush_callback(@buffer_index, @buffer)
		@buffer_index

exports = module.exports =
	STDIO_CHANNEL: STDIO_CHANNEL
	STDIO_FEOF: STDIO_FEOF
	STDIO_FSEEK: STDIO_FSEEK
	STDIO_FSEEK_FROM: STDIO_FSEEK_FROM
	STDIO_READ: STDIO_READ
	STDIO_WRITE: STDIO_WRITE
	STDIO_IN: STDIO_IN
	STDIO_OUT: STDIO_OUT
	STDIO_ERR: STDIO_ERR
	STDIO_FLUSH: STDIO_FLUSH
	SEEK_CURR: SEEK_CURR
	SEEK_START: SEEK_START
	SEEK_END: SEEK_END
	Stdio: Stdio
exports[feature.FEATURE_NAME] = FEATURE_STDIO
exports[feature.FEATURE_CLASS] = Stdio
