# Halt feature
#
# Captures the event of an endless loop:
#   add abs0, 0, cp
#
# TODO: Support for interrupts.
#

{Feature, FEATURE_NAME, FEATURE_CLASS} = require('features/feature')

FEATURE_HALT = 'halt'
HALTED_VAR = 'halted'

class Halt extends Feature
	constructor: (halt_callback) ->
		@halt_callback = halt_callback
		super FEATURE_HALT

	handle_load_into: (cpu) ->
		feature = @
		((real_execute) ->
			cpu[HALTED_VAR] = false
			cpu.execute = (sp, src, add, dst) ->
				# Compatibility check
				if arguments.length != 4
					# Not built for this version. Restore original handler
					@execute = real_execute
					@execute.apply @, arguments
				else if @[HALTED_VAR]
					0 # Do nothing
				else if (src == @abs0 && add == 0 && dst == @cp)
					@[HALTED_VAR] = true
					feature.halt_callback(@) if feature.halt_callback?
					0 # Do nothing
				else real_execute.call(cpu, sp, src, add, dst)
			return
		)(cpu.execute)

exports.Halt = Halt
exports[FEATURE_NAME] = FEATURE_HALT
exports[FEATURE_CLASS] = Halt