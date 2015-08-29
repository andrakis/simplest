# Flags feature
#
# Instead of updating every special register every cycle, they can be
# entirely turned off or entirely turned on.
#
# TODO: Ability to selective disable special register calculations.

{Feature, FEATURE_NAME, FEATURE_CLASS} = require('features/feature')
{vlog} = require('verbosity')
{decSymbol} = require('symbols')

FEATURE_FLAGS = decSymbol 'FEATURE_FLAGS', 'flags'

class Flags extends Feature
	constructor: () ->
		super FEATURE_FLAGS

	handle_load_into: (cpu) ->
		feature = @
		((update_flags) ->
			cpu.update_flags = (sp, val) ->
				feature.handle_update_flags sp, val, cpu, update_flags
		)(cpu.update_flags)
	
	handle_initialize: (cpu, real_initialize) ->
		vlog 100, 'Flags initialize'
		super cpu, real_initialize
		@flags = cpu.flags = cpu.defReg 'flags'
		cpu.write @flags, 0x01

	handle_update_flags: (sp, val, cpu, real_update_flags) ->
		flags = cpu.read(sp + @flags)
		vlog(30, "Flags is #{flags}")
		if flags & 0x01
			vlog(30, "Flags updating")
			real_update_flags.call cpu, sp, val
		val
decSymbol 'Flags', Flags

exports.Flags = Flags
exports[FEATURE_NAME] = FEATURE_FLAGS
exports[FEATURE_CLASS] = Flags

decSymbol 'Flags.exports', exports