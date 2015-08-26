# DMA feature for TinyCpu
#
# Allows ranges of memory to be assigned to a callback. The callback can then
# process the read or write, as well as any other logic to do with the value in
# question.
#

{Feature, FEATURE_NAME, FEATURE_CLASS} = require('features/Feature')

DEBUG = true

FEATURE_DMA = 'DMA'

# [] =
#	start: 0
#	end: 1
#	name: "feature name"
#   instance: @
dma_ranges = []

register_range = (start, end, instance) ->
	if start > end
		# Switch the values
		`start = start ^ end ^ (end ^ = (start ^ end))`
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
		@debug = DEBUG unless @debug?
		@name = "generic DMA device" unless @name
		super FEATURE_DMA

		if !register_range @rangeStart, @rangeEnd
			feature = find_feature @rangeStart
			throw "range in use by #{feature.name}"
		@log "device(#{@name}) registered"
	
	offset: (loc) -> loc - @rangeStart
	log: () ->
		# TODO: Replace with something better
		if @debug
			console.log.apply(console, arguments)
		return

	handle_read: (loc, cpu) ->
		offset = @offset loc
		result = @dma_read offset, cpu
		log "dma_read(#{offset}) = #{result}"
		result
	
	handle_write: (loc, value, cpu) ->
		offset = @offset loc
		result = @dma_write offset, value, cpu
		log "dma_write(#{offset}) = #{result}"
		result
	
	dma_read: (loc, cpu) ->
		# Dummy implementation.
		0
	
	dma_write: (loc, value, cpu) ->
		# Dummy implementation. Write fails.
		0

exports = module.exports || {}
exports[FEATURE_NAME]  = FEATURE_DMA
exports[FEATURE_CLASS] = DMA
exports.register_feature = register_feature
exports.find_feature = find_feature