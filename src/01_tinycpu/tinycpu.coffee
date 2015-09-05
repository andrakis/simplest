# This is the TinyCPU, it is designed around the Cumulative CPU.
#
# It is a One Instruction Set design, with the instruction being:
#   add *src, increment_amount, dst
#     Read from memory at src, add increment_amount, store to dst
#     dst is always relative to the current sp. To get an absolute location,
#     you must use abs0:
#        Code to add dst and abs0 together, and store a value into
#         the resulting destination:
#        0, 0, ac      # Clear ac
#        0, DST, r0    # Observe DST
#        abs0, 0, abs0 # Observe abs0
#        ac, 0, r1     # r1 now holds DST + abs0
#
# There are some special registers which update after each operation:
#   ac           Accumulator
#   dc           Decumulator
#  (The following registers are set to the value of opsz if true)
#   eq0          Whether the last value was == 0
#   mt0          "                        "  > 0
#   lt0          "                        " <  0
# Along with these, there are a few generic registers:
#   abs0         Pointer to memory location 0, which should always be 0
#   sp           Stack pointer
#   psp          Previous stack pointer (for returns)
#   cp           Code pointer
#   opsz         Opsize. Each operation takes 3 values. This means a jump
#                operation needs to jump 3 places for each instruction set.
#   flags        Enables eq0, mt0, and lt0 if bit 1 is on
#   r1 - r2      General purpose registers.
#
# Memory is a hash of numbers. For lazyness, this is not using any strict
# data type.
#
# Additional features can be loaded into a TinyCpu instance. See features/

{vlog} = require 'verbosity'
{decSymbol} = require 'symbols'

class TinyCPU
	constructor: () ->
		@memory = {}
		@registers = {}
		@register_count = 0

	initialize: () ->
		vlog 100, 'CPU initialize'
		@abs0 = @defReg 'abs0'
		@sp = @defReg 'sp'
		@psp = @defReg 'psp'
		@cp = @defReg 'cp'
		@ac = @defReg 'ac'
		@dc = @defReg 'dc'
		@opsz = @defReg 'opsz'
		@eq0 = @defReg 'eq0'
		@mt0 = @defReg 'mt0'
		@lt0 = @defReg 'lt0'
		@r1 = @defReg 'r1'
		@r2 = @defReg 'r2'
		@new_stack 0
		vlog 100, "Writing opsize 3 to #{@opsz}"
		@opsize = @write @opsz, 3         # Size of an instruction, 3 values

	defReg: (name) ->
		vlog 100, "Defining register #{name}"
		pos = @register_count++
		@registers[name] = pos
		@registers[pos] = name
		decSymbol name, pos
		pos
	
	load: (loc, data) ->
		# This is just neater in javascript
		vlog 100, "Loading #{data.length} bytes into #{loc}"
		`for (var i = 0; i < data.length; i++, loc++) this.write(loc, data[i])`
		return
	
	new_stack: (start, psp) ->
		vlog 100, "Creating new stack at #{start}"
		offset = 0
		for i in [0..@register_count]
			@write start + offset++, 0
		# Setup previous stack pointer
		@write start + @psp, psp || 0
		# Adjust abs0 to point to 0, relative to current sp
		@write start + @abs0, -start
		return
	
	read: (loc) -> @memory[loc] || 0
	write: (loc, value) -> @memory[loc] = value || 0

	enable_debug: (enable) ->
		self = @
		((read, write) ->
			if !enable
				self.read = read
				self.write = write
			else
				self.read = (loc) ->
					v = read.call(self, loc)
					vlog(70, "cpu.read(", loc, ") = ", v)
					v
				self.write = (loc, value) ->
					prev = read.call(self, loc)
					vlog(70, "cpu.write(", loc, ", ", value, ") prev=", prev)
					write.call(self, loc, value)
		)(self.read, self.write)

	cycle: () ->
		@fetch()
	
	fetch: () ->
		sp = @read @sp
		cp = @read sp + @cp
		src = @read cp
		add = @read cp + 1
		dst = @read cp + 2
		vlog(20, "Fetch, sp=", sp, ", cp=", cp, ", src=", @registers[src - sp] || src, "add=", add, "dst=", @registers[dst - sp] || dst)
		@execute sp, src, add, dst
	
	execute: (sp, src, add, dst) ->
		vlog(40, "execute(", [sp, src, add, dst].join(', '), ")")
		vlog(60, "(sp=", sp, ")", @registers[src - sp] || src, " + ", add, "->", @registers[dst - sp] || dst)
		val = @write dst, @read(src) + add
		opsz = @read(sp + @opsz)
		vlog(90, "Updating cp by #{opsz}...")
		@write sp + @cp, @read(sp + @cp) + opsz
		vlog(90, "Cp is now ", @read sp + @cp)
		@update_flags sp, val
	
	update_flags: (sp, val) ->
		@write sp + @ac, @read(sp + @ac) + val
		@write sp + @dc, @read(sp + @dc) - val
		@write @eq0, if (val == 0) then @opsize else 0
		@write @mt0, if (val  > 0) then @opsize else 0
		@write @lt0, if (val <  0) then @opsize else 0
		val

decSymbol 'TinyCPU', TinyCPU

exports = ex = module.exports =
	TinyCPU: TinyCPU

decSymbol 'TinyCPU.exports', ex
