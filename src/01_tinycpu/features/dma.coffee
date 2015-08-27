# DMA feature for TinyCpu
#
# Allows ranges of memory to be assigned to a callback. The callback can then
# process the read or write, as well as any other logic to do with the value in
# question.
#

{Feature, FEATURE_NAME, FEATURE_CLASS} = require('features/feature')
{vlog} = require('verbosity')

DEBUG = true

FEATURE_DMA = 'DMA'

# [] =
#	start: 0
#	end: 1
#	name: "feature name"
#   instance: @
dma_ranges = []

register_range = (start, end, instance) ->
	throw "Instance required in register_range(" + start + ", " + end + ")" if !instance
	if start > end
		# Switch the values
		tmp = start
		start = end
		end = tmp
	# TODO: This isn't a very robust check.
	for feature in dma_ranges
		if feature.start >= start && feature.end >= start
			return false
	dma_ranges.push
		start: start
		end: end
		name: instance.name
		instance: instance
	true

find_feature = (start) ->
	for feature in dma_ranges
		if feature.start >= start && feature.end < start
			feature
	null

class DMA extends Feature
	constructor: (options) ->
		{@rangeStart, @rangeEnd, @debug, @name} = options
		@rangeStart = Math.min(@rangeStart, @rangeEnd)
		@rangeEnd = Math.max(@rangeStart, @rangeEnd)
		@debug = DEBUG unless @debug?
		@name = "generic DMA device" unless @name
		super @name

		if !register_range @rangeStart, @rangeEnd, @
			feature = find_feature @rangeStart
			throw "range in use by #{feature.name}"
		vlog 10, "device(#{@name}, #{@rangeStart} ... #{@rangeEnd}) registered"
	
	offset: (loc) -> loc
	
	isInRange: (loc) ->
		vlog 70, @name, " range is ", @rangeStart, " .. ", @rangeEnd
		if @rangeStart > 0 && @rangeEnd > 0
			vlog 80, "Comp1: loc(", loc, ") >= @rangeStart(", @rangeStart, ") && loc <= @rangeEnd(", @rangeEnd, ")"
			(loc >= @rangeStart && loc <= @rangeEnd)
		else if @rangeStart < 0 && @rangeEnd < 0
			if @rangeStart > @rangeEnd
				vlog 80, "Comp2: loc(", loc, ") >= @rangeStart(", @rangeStart, ") && loc <= @rangeEnd(", @rangeEnd, ")"
				(loc >= @rangeStart && loc <= @rangeEnd)
			else
				vlog 80, "Comp3: loc(", loc, ") >= @rangeStart(", @rangeStart, ") && loc <= @rangeEnd(", @rangeEnd, ")"
				(loc >= @rangeStart && loc <= @rangeEnd)
		else
			false

	handle_read: (loc, cpu, real_read) ->
		match = @isInRange loc
		if match
			offset = @offset loc
			result = @dma_read offset, cpu
		else
			offset = loc
			result = real_read loc
		vlog 70, "dma_read(#{offset}) = #{result}" + (if match then "(dma handled)" else "(not handled)" )
		result
	
	handle_write: (loc, value, cpu, real_write) ->
		match = @isInRange loc
		vlog 90, "Is ", loc, " in range for ", @name, "?", (match ? "yes" : "no")
		if match
			offset = @offset loc
			result = @dma_write offset, value, cpu
		else
			offset = loc
			result = real_write loc, value
		vlog 70, "dma_write(#{offset}) = #{result} " + (match ? "(dma handled)" : "(not handled)" )
		result
	
	dma_read: (loc, cpu) ->
		# Dummy implementation.
		vlog(30, 'WARN: Dummy dma_read in ', @name)
		0
	
	dma_write: (loc, value, cpu) ->
		# Dummy implementation. Write fails.
		vlog(30, 'WARN: Dummy dma_write in ', @name)
		0

exports = module.exports || {}
exports[FEATURE_NAME]  = FEATURE_DMA
exports[FEATURE_CLASS] = DMA
exports.register_feature = register_range
exports.find_feature = find_feature
