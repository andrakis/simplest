require('coffee-script/register')
{Feature} = require('../features/feature')
{Halt} = require('../features/watchers/halt')
{Stdio, Buffer, STDIO_OUT, STDIO_CHANNEL, STDIO_WRITE, STDIO_FLUSH,
 STDIO_FEOF, STDIO_IN, STDIO_OUT, STDIO_ERR} = require('../features/io/stdio')
{TinyCPU} = require('tinycpu')
{vlog} = require('verbosity')

vlog(50, "TinyCPU", TinyCPU)
cpu = new TinyCPU
cpu.enable_debug true

# Register a callback for the halt feature
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

vlog(30, stdio.get_features(cpu).join(', '), 'loaded into test CPU')

charCode = (S) -> ("" + S).charCodeAt(0)

{abs0, cp, ac, r1, r2} = cpu.registers

# Write a small program to print "Hello World!" via STDOUT
hello = [
	# Select STDOUT
	abs0, STDIO_OUT, STDIO_CHANNEL
	# Write string
	abs0, charCode('H'), STDIO_WRITE
	abs0, charCode('e'), STDIO_WRITE
	abs0, charCode('l'), STDIO_WRITE
	abs0, charCode('l'), STDIO_WRITE
	abs0, charCode('o'), STDIO_WRITE
	abs0, charCode(','), STDIO_WRITE
	abs0, charCode(' '), STDIO_WRITE
	abs0, charCode('w'), STDIO_WRITE
	abs0, charCode('o'), STDIO_WRITE
	abs0, charCode('r'), STDIO_WRITE
	abs0, charCode('l'), STDIO_WRITE
	abs0, charCode('d'), STDIO_WRITE
	abs0, charCode('!'), STDIO_WRITE
	# Flush
	abs0, STDIO_FLUSH, STDIO_CHANNEL
	# Attempt to read from STDIN
	abs0, STDIO_IN, STDIO_CHANNEL
	STDIO_FEOF, 0, r1
	# Add '0' to result and print
	0, 0, ac   # Clear AC
	r1, 0, r1  # Observe r1
	0, 48, r2  # Add 48
	ac, 0, r1  # Grab result and store to r1
	abs0, STDIO_OUT, STDIO_CHANNEL  # Back to output channel
	r1, 0, STDIO_WRITE # Write result
	abs0, STDIO_FLUSH, STDIO_CHANNEL # Flush
	# Endless loop
	abs0, 0, cp
]
vlog(50, "Code: ", hello)
cpu.load 100, hello
# Setup entry point
cpu.write cp, 100
# Debug
vlog(50, cpu.memory)

cycles = 10
while halted == false
	cpu.cycle()
vlog(20, "CPU halted, quitting")
