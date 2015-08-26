# Provides a base class for implementing interrupts.
#
#

{Feature, FEATURE_NAME, FEATURE_CLASS} = require('feature')

FEATURE_INT = 'interrupt'

INTERRUPTS_VAR = 'interrupts'
TIMER_VAR = 'interrupts_timer'
FREQ_VAR = 'interrupts_freq'
LAST_VAR = 'interrupts_last_int'

# Once every 500ms
DEFAULT_FREQ = 500

class Interrupt extends Feature
	constructor: (interrupt_number) ->
		@number = interrupt_number

	handle_load_into: (cpu) ->
		@initialize cpu unless cpu[INTERRUPTS_VAR]?
		return
	
	initialize: (_cpu) ->
		feature = @
		cpu[INTERRUPTS_VAR] = []
		cpu[TIMER_VAR] = 0
		cpu[FREQ_VAR] = DEFAULT_FREQ
		cpu[LAST_VAR] = feature.timestamp()
		cpu.handle_interrupts = () -> feature.handle_interrupts @
		((real_cycle) ->
			cpu.cycle = () ->
				timestamp = feature.timestamp()
				if timestamp - this[LAST_VAR] >= this[FREQ_VAR]
					@[TIMER_VAR]++
					@handle_interrupts()
					@[LAST_VAR] = feature.timestamp()
				@fetch()
		)(cpu.cycle)
		return
	
	timestamp: () -> (new Date).getTime()

	handle_interrupts: (cpu) ->
		