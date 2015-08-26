require('coffee-script/register')
{Feature} = require('../features/feature')
{Halt} = require('../features/watchers/halt')
{Stdio, Buffer, STDIO_OUT, STDIO_CHANNEL, STDIO_WRITE, STDIO_FLUSH, STDIO_IN, STDIO_OUT, STDIO_ERR} = require('../features/io/stdio')
{TinyCPU} = require('tinycpu')

console.log("TinyCPU", TinyCPU)
cpu = new TinyCPU
cpu.enable_debug true

halted = false
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

charCode = (S) -> ("" + S).charCodeAt(0)

{abs0, cp} = cpu.registers

# Write a small program to print "Hello World!" via STDOUT
hello = [
	# Select STDOUT
	abs0, STDIO_OUT, STDIO_CHANNEL,
	# Write string
	abs0, charCode('H'), STDIO_WRITE,
	abs0, charCode('e'), STDIO_WRITE,
	abs0, charCode('l'), STDIO_WRITE,
	abs0, charCode('l'), STDIO_WRITE,
	abs0, charCode('o'), STDIO_WRITE,
	abs0, charCode(' '), STDIO_WRITE,
	abs0, charCode('W'), STDIO_WRITE,
	abs0, charCode('o'), STDIO_WRITE,
	abs0, charCode('r'), STDIO_WRITE,
	abs0, charCode('l'), STDIO_WRITE,
	abs0, charCode('d'), STDIO_WRITE,
	abs0, charCode('!'), STDIO_WRITE,
	# Flush
	abs0, STDIO_FLUSH, STDIO_CHANNEL
	# Endless loop
	abs0, 0, cp
]
console.log("Code: ", hello)
cpu.load 100, hello
# Setup entry point
cpu.write cp, 100
# Debug
console.log(cpu.memory)

while halted == false
	cpu.cycle()