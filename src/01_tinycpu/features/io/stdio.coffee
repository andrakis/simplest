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

DMA = dma[feature.FEATURE_CLASS]

FEATURE_STDIO = 'stdio'

STDIO_MAGIC_MAGIC = 0xDEADBEEF01

# Memory ranges
STDIO_MAGIC   = 0
STDIO_CHANNEL = 1
STDIO_FEOF    = 2
STDIO_FSEEK   = 3
STDIO_FSEEK_FROM = 4
STDIO_READ    = 5
STDIO_WRITE   = 6
RANGE = [-10, -4]

STDIO_IN = 0
STDIO_OUT = 1
STDIO_ERR = 2
STDIO_FLUSH = 11

SEEK_CURR = 0
SEEK_START = 1
SEEK_END = 2

class Stdio extends DMA
	@buffer_stdin = new Buffer
	@buffer_stdout = new Buffer
	@buffer_stderr = new Buffer
	@buffers = [@buffer_stdin, @buffer_stdout, @buffer_stderr]
	@buffer_index = 0
	@buffer = @buffers[@buffer_index]
	@fseek_from = SEEK_CURR

	constructor: (flush_callback) ->
		@flush_callback = flush_callback
		super
			name: "standard io"
			rangeStart: RANGE[0]
			rangeEnd: RANGE[1]
	
	dma_read: (loc, cpu) ->
		switch loc
			when STDIO_MAGIC   then STDIO_MAGIC_MAGIC
			when STDIO_CHANNEL then @buffer_index
			when STDIO_FEOF    then @buffer.feof()
			when STDIO_FSEEK   then 0 # not supported
			when STDIO_FSEEK_FROM then @fseek_from
			when STDIO_READ    then @buffer.read()
			when STDIO_WRITE   then 0 # not supported
	
	dma_write: (loc, value, cpu) ->
		switch loc
			when STDIO_MAGIC   then 0 # not supported
			when STDIO_CHANNEL then @switch_buffer value
			when STDIO_FEOF    then 0 # not supported
			when STDIO_FSEEK   then @buffer.fseek value, @fseek_from
			when STDIO_FSEEK_FROM then @fseek_from = value
			when STDIO_READ    then 0 # not supported
			when STDIO_WRITE   then @buffer.write value
	
	switch_buffer: (buffer) ->
		if buffer >= 0 && buffer < @buffers.length
			@buffer = @buffers[@buffer_index = buffer]
			buffer
		else if buffer == STDIO_FLUSH
			@handle_flush
		else
			throw "stdio: switch_buffer(#{buffer}): invalid buffer"
	
	handle_flush: () ->
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