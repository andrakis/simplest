# Features test
#
# This is a generic test for the TinyCPU and some features.
# It tests two useful ones:
#
#  halt     When CPU encounters endless jump, calls callback to
#           allow the host process to stop CPU execution.
#  stdio    Allows input / output across streams
#
# The test loads both of these features into a CPU instance,
# then compiles some code to work with stdio. The final command
# is the endless jump: abs0, 0, cp
#

require('coffee-script/register')
{Feature} = require('../features/feature')
{Halt} = require('../features/watchers/halt')
{Flags} = require('../features/watchers/flags')
{Stdio, Buffer, STDIO_OUT, STDIO_CHANNEL, STDIO_WRITE, STDIO_FLUSH,
 STDIO_FEOF, STDIO_IN, STDIO_ERR} = require('../features/io/stdio')
{TinyCPU} = require('tinycpu')
{vlog} = require('verbosity')
symbols = require('symbols')
{charCode} = require('tc_util')
{Paging} = require('features/mm/paging')

vlog(50, "TinyCPU", TinyCPU)
cpu = new TinyCPU
cpu.enable_debug true

# Register a callback for the halt feature
halted = false
(new Halt(() -> halted = true)).load_into cpu

# Enable the flags feature, which greatly cuts down on debugging output
(new Flags).load_into cpu

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

paging = false
paging = new Paging
paging.load_into cpu

# Page the range before we load code in
if paging
	paging.page_range 0, 500

# All features in place, now we can initialize cpu and load code
vlog(30, stdio.get_features(cpu).join(', '), 'loaded into test CPU')
cpu.initialize()

#vlog(30, "Symbols:", symbols.getSymbols())
#vlog 10, "CPU: ", cpu
{abs0, cp, ac, flags, r1, r2} = cpu.registers

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
	# Check if STDIN is at EOF
	abs0, STDIO_IN, STDIO_CHANNEL
	STDIO_FEOF, 0, r1
	# Add '0' to result and print
	# We need flags again
	abs0, 0x01, flags
	0, 0, ac   # Clear AC
	r1, 0, r1  # Observe r1
	0, 48, r2  # Add 48, ASCII for '0'
	ac, 0, r1  # Grab result and store to r1
	abs0, STDIO_OUT, STDIO_CHANNEL  # Back to output channel
	r1, 0, STDIO_WRITE # Write result
	abs0, STDIO_FLUSH, STDIO_CHANNEL # Flush
	# Disable flags
	abs0, 0x0, flags
	# Endless loop
	abs0, 0, cp
]
vlog(50, "Code: [", hello.join(', '), "]")

# Disable the flags register to reduce spam. It can be re-enabled in code
# when needed.
cpu.write flags, 0x00
cpu.load 100, hello
# Setup entry point
cpu.write cp, 100

# Run the cpu until halted
cycles = -1
while halted == false && cycles-- != 0
	cpu.cycle()
vlog(20, "CPU halted, quitting")
