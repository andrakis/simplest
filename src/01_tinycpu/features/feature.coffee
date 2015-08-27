# Provides a feature for TinyCpu
#
# Extend this class to implement your own features.
#

{vlog} = require('verbosity')

CPU_FEATURE_VAR = '_features'
FEATURE_NAME    = 'name'
FEATURE_CLASS   = 'class'

class Feature
	constructor: (name) ->
		@name = name

	has_feature: (name, cpu) -> name of cpu[CPU_FEATURE_VAR]
	
	get_feature: (name, cpu) -> cpu[CPU_FEATURE_VAR][name]
	
	get_features: (cpu) -> feature for feature of cpu[CPU_FEATURE_VAR]

	read: (loc, cpu, real_read) -> real_read.call(cpu, loc)
	
	write: (loc, value, cpu, real_write) -> real_write.call(cpu, loc, value)
	
	interrupt: (num, cpu) -> @handle_interrupt num, cpu
	
	handle_read: (loc, cpu, real_read) ->
		# Dummy implementation. Reads that value from cpu memory
		vlog(100, "self is", @)
		vlog(50, "handle_read(", [loc].join(', '), "): Feature dummy implementation")
		real_read.call cpu, loc
	
	handle_write: (loc, value, cpu, real_write) ->
		# Dummy implementation. Writes that value to loc on cpu memory
		vlog(50, "handle_write(", [loc, value].join(', '), "): Feature dummy implementation")
		real_write.call cpu, loc, value
	
	handle_interrupt: (num, cpu) ->
		# Dummy implementation. Does nothing.
	
	# Load the feature into the CPU
	load_into: (cpu) ->
		vlog(10, "Loading", @name, "into CPU instance")
		name = @name
		((instance, feature) ->
			((read, write, interrupt) ->
				if !instance[CPU_FEATURE_VAR]?
					instance[CPU_FEATURE_VAR] = {}
				instance.read = (loc) -> feature.handle_read loc, instance, read
				instance.write = (loc, value) -> feature.handle_write loc, value, instance, write
				instance.interrupt = (num) -> feature.interrupt num, instance
				instance[CPU_FEATURE_VAR][name] = feature
				feature.handle_load_into instance
				instance
			)(instance.read, instance.write, instance.interrupt)
		)(cpu, @)
	
	handle_load_into: (cpu) ->
		# Dummy implementation.

exports = module.exports =
	CPU_FEATURE_VAR: CPU_FEATURE_VAR
	FEATURE_NAME: 'name'
	FEATURE_CLASS: FEATURE_CLASS
	Feature: Feature
