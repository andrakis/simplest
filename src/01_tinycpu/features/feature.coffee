# Provides a feature for TinyCpu
#
# Extend this class to implement your own features.
#

CPU_FEATURE_VAR = '_features'
FEATURE_NAME    = 'name'
FEATURE_CLASS   = 'class'

class Feature
	constructor: (name) ->
		@name = name

	has_feature: (name, cpu) -> name of cpu[CPU_FEATURE_VAR]
	
	get_feature: (name, cpu) -> cpu[CPU_FEATURE_VAR][name]
	
	get_features: (cpu) -> feature for feature of cpu[CPU_FEATURE_VAR]

	read: (loc, cpu) -> @handle_read loc, cpu
	
	write: (loc, value, cpu) -> @handle_write loc, value, cpu
	
	interrupt: (num, cpu) -> @handle_interrupt num, cpu
	
	handle_read: (loc, cpu) ->
		# Dummy implementation. Reads that value from cpu memory
		cpu.real_read loc
	
	handle_write: (loc, value, cpu) ->
		# Dummy implementation. Writes that value to loc on cpu memory
		cpu.real_write loc, value
	
	handle_interrupt: (num, cpu) ->
		# Dummy implementation. Does nothing.
	
	# Load the feature into the CPU
	load_into: (cpu) ->
		((instance, feature) ->
			if !instance[CPU_FEATURE_VAR]?
				instance.real_read = instance.read
				instance.real_write = instance.write
				instance.read = (loc) -> feature.read loc, instance
				instance.write = (loc, value) -> feature.write loc, value, instance
				instance.interrupt = (num) -> feature.interrupt num, instance
				instance[CPU_FEATURE_VAR] = {}
			instance[CPU_FEATURE_VAR][@name] = feature
			feature.handle_load_into instance
			instance
		)(cpu, @)
	
	handle_load_into: (cpu) ->
		# Dummy implementation.

exports = module.exports =
	CPU_FEATURE_VAR: CPU_FEATURE_VAR
	FEATURE_NAME: 'name'
	FEATURE_CLASS: FEATURE_CLASS
	Feature: Feature