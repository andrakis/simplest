require('coffee-script/register')
{Feature} = require('../features/feature')
{Halt} = require('../features/watchers/halt')
{Stdio, Buffer, STDIO_IN, STDIO_OUT, STDIO_ERR} = require('../features/io/stdio')
{TinyCPU} = require('tinycpu')

console.log("TinyCPU", TinyCPU)
cpu = new TinyCPU

halted = false
console.log("Loading halt")
(new Halt(() -> halted = true)).load_into cpu

stdio = new Stdio((buffer_index, buffer) ->
	# Handle a flush event
	stream = switch buffer_index
		when STDIO_IN  then "stdin"
		when STDIO_OUT then "stdout"
		when STDIO_ERR then "stderr"
	content = buffer.flush()
	console.log "(#{stream}) #{content}"
	return
)
stdio.load_into cpu

console.log(stdio.get_features(cpu).join(', '), 'loaded into test CPU')