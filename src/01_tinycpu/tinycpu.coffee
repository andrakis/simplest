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
#   r1 - r2      General purpose registers.
#
# Memory is a hash of numbers. For lazyness, this is not using any strict
# data type.
#
# Additional features can be loaded into a TinyCpu instance. See features/

class TinyCPU
	@memory = {}
	@registers = {}
	@register_count = 0

	constructor: () ->
		@abs0 = @defReg 'abs0'
		@sp = @defReg 'sp'
		@psp = @defReg 'psp'
		@cp = @defReg 'cp'
		@ac = @defReg 'ac'
		@dc = @defReg 'dc'
		@opsz = @defReg 'opsz'
		@opsize = @write @opsz, 3         # Size of an instruction, 3 values
		@eq0 = @defReg 'eq0'
		@mt0 = @defReg 'mt0'
		@lt0 = @defReg 'lt0'
		@r1 = @defReg 'r1'
		@r2 = @defReg 'r2'

	defReg: (name) ->
		pos = @register_count++
		registers[name] = pos
		registers[pos] = name
		pos
	
	load: (loc, data) ->
		# This is just neater in javascript
		`for (var i = 0; i < data.length; i++, loc++) this.write(loc, data[i])`
		return
	
	read: (loc) -> @memory[loc]
	write: (loc, value) -> @memory[loc] = value
	inc_r: (loc) -> @write(loc, @read(loc) + 1)
	dec_r: (loc) -> @write(loc, @read(loc) - 1)
	
	cycle: () ->
		fetch()
	
	fetch: () ->
		sp = @read @sp
		cp = @read sp + @cp
		src = @inc_r cp
		add = @inc_r cp
		dst = @inc_r cp
		execute sp, src, add, dst
	
	execute: (sp, src, add, dst) ->
		val = @write dst, @read(src) + add
		@write sp + @ac, @read(sp + @ac) + val
		@write sp + @dc, @read(sp + @dc) - val
		@write @eq0, if (val == 0) then @opsize else 0
		@write @mt0, if (val  > 0) then @opsize else 0
		@write @lt0, if (val <  0) then @opsize else 0
		val

exports.TinyCPU = TinyCPU