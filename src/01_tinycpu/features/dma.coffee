# DMA feature for TinyCpu
#
# Allows ranges of memory to be assigned to a callback. The callback can then
# process the read or write, as well as any other logic to do with the value in
# question.
#

{Feature, FEATURE_NAME, FEATURE_CLASS} = require('features/feature')
{vlog} = require('verbosity')
{decSymbol} = require('symbols')

exports = exports || {}

DEBUG = true

FEATURE_DMA = decSymbol 'FEATURE_DMA','DMA'

DMA_DISABLED = decSymbol 'DMA_DISABLED', NaN

# [] =
#	start: 0
#	end: 1
#	name: "feature name"
#   instance: @
dma_ranges = []

check_range = (start, end) ->
	if start > end
		# Switch the values
		tmp = start
		start = end
		end = tmp
	return {
		start: start
		end: end
	}

register_range = (start, end, instance, dma_id) ->
	throw "Instance required in register_range(" + start + ", " + end + ")" if !instance
	{start, end} = check_range start, end

	# TODO: This isn't a very robust check.
	for feature in dma_ranges
		if feature.start >= start && feature.end >= start
			return false
	dma_ranges.push
		start: start
		end: end
		name: instance.name
		instance: instance
		id: dma_id
	true

deregister_range = (start, end) ->
	throw "Instance required in register_range(" + start + ", " + end + ")" if !instance
	{start, end} = check_range start, end

	# TODO: This isn't a very robust check.
	i = 0
	while i < dma_ranges.length
		if feature.start >= start && feature.end >= start
			# Remove this one
			return dma_ranges.splice i, 1
		i++
	# Not found
	false

find_feature = (start) ->
	for feature in dma_ranges
		if feature.start >= start && feature.end < start
			feature
	null

class DMA extends Feature
	constructor: (options) ->
		{@rangeStart, @rangeEnd, @debug, @name, @ranges} = options
		@range_id_counter = 0
		@ranges = []
		@debug = DEBUG unless @debug?
		@name = "generic DMA device" unless @name
		super @name

		if isNaN(@rangeStart)
			if isNaN(@rangeEnd)
				@ranges.pop()
				vlog 10, "device(#{@name}) registered with no current DMA range"
			else
				throw "DMA_DISABLED must be used for start and end"
		else
			result = @declare_range @rangeStart, @rangeEnd
			if result == false
				feature = find_feature @rangeStart
				throw "range in use by #{feature.name}"
				
	new_range: (start, end) ->
		start: Math.min(start, end)
		end: Math.max(start, end)
		id: @range_id_counter++
	
	# Declare a new DMA range. An id will be returned, this id is set on the
	# class variable @dma_id to indicate which registered range was triggered.
	declare_range: (start, end) ->
		range = @new_range start, end
		if !register_range start, end, @, range.id
			false
		@ranges.push range
		vlog 10, "DMA device(#{@name}, #{range.start} ... #{range.end}) registered at #{range.id}"
		range.id
		
	remove_range: (start, end) ->
		result = deregister_range start, end
		return false  unless result
		result.id

	offset: (loc) -> loc
	
	isInRange: (loc) ->
		vlog 70, @name, " range is: ", @ranges
		for range in @ranges
			start = range.start
			end = range.end
			id = range.id
			found = false
			if start >= 0 && end >= 0
				vlog 80, "Comp1: loc(", loc, ") >= start(", start, ") && loc <= end(", end, ")"
				found = (loc >= start && loc <= end)
			else if start <= 0 && end <= 0
				if start > end
					vlog 80, "Comp2: loc(", loc, ") >= start(", start, ") && loc <= end(", end, ")"
					found = (loc >= start && loc <= end)
				else
					vlog 80, "Comp3: loc(", loc, ") >= start(", start, ") && loc <= end(", end, ")"
					found = (loc >= start && loc <= end)
			else
				vlog 10, "Missing a comparison for #{start} .. #{end}"
			if found
				vlog 50, "Found matching entry at DMA id #{id}, ranges: ", @ranges
				return {id: id}
		false

	handle_read: (loc, cpu, real_read) ->
		match = @isInRange loc
		if match
			@dma_id = match.id
			offset = @offset loc
			result = @dma_read offset, cpu
		else
			offset = loc
			result = real_read loc
		vlog 70, "dma_read(#{offset}) = #{result}" + (if match then " (dma handled by #{@name}.#{match.id})" else "(not handled by #{@name})" )
		result
	
	handle_write: (loc, value, cpu, real_write) ->
		match = @isInRange loc
		if match
			@dma_id = match.id
			offset = @offset loc
			result = @dma_write offset, value, cpu
		else
			offset = loc
			result = real_write loc, value
		vlog 70, "dma_write(#{offset}, #{value}) = #{result}" + (if match then " (dma handled by #{@name}.#{match.id})" else " (not handled by #{@name})" )
		result
	
	dma_read: (loc, cpu) ->
		# Dummy implementation.
		vlog(30, 'WARN: Dummy dma_read in ', @name)
		0
	
	dma_write: (loc, value, cpu) ->
		# Dummy implementation. Write fails.
		vlog(30, 'WARN: Dummy dma_write in ', @name)
		0

decSymbol "DMA", DMA

exports = module.exports || {}
exports[FEATURE_NAME]  = FEATURE_DMA
exports[FEATURE_CLASS] = DMA
exports.register_feature = register_range
exports.find_feature = find_feature
exports.DMA_DISABLED = DMA_DISABLED

decSymbol "DMA.exports", exports