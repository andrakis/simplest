# The paging memory management scheme.
#
# Borrows the implementation of the C port of Cumulative, Gleam, to implement
# paged-based memory access. Regions of memory can be protected, triggering
# interrupts upon reading or writing to memory.
#
# The pages can be unloaded from memory, to allow paging to disk or # some other
# medium.
#
# There is no defined datatype for the cells on a page. This is left up to
# other feature to implement specific types.
#

{decSymbol} = require 'symbols'
feature = require 'features/feature'
dma = require 'features/dma'
{vlog} = require 'verbosity'
{clone} = require 'tc_util'
Pages = require 'features/mm/support/pages'

DMA = dma[feature.FEATURE_CLASS]
{DMA_DISABLED} = dma
{FEATURE_NAME, FEATURE_CLASS} = feature

PGSTATS_PAGES_ALLOCATED = decSymbol 'PGSTATS_PAGES_ALLOCATED', 'pages_allocated'

# Copy all the exported symbols from Pages into this module
for key, value of Pages
	exports[key] = value

class Paging extends DMA
	constructor: (Options) ->
		Options = Options || {}
		{@pageSize, @implementation} = Options
		@pageSize = @pageSize || Pages.options.PageSize
		@implementation = @implementation || Pages.options.PageImplementation
		@stats = {}
		@head = @allocate 0
		@stat PGSTATS_PAGES_ALLOCATED, 1
		super
			rangeStart: DMA_DISABLED
			rangeEnd: DMA_DISABLED
			name: "Paging"
	
	# Public API.
	
	read: (location) ->
		@reset_head location
		@head.read location - @head.start
	
	write: (location, value) ->
		@reset_head location
		@head.write location - @head.start, value
	
	get_stats: () -> clone @stats

	# Page the given range
	page_range: (start, end) ->
		dma_range_id = @declare_range start, end
		return false  unless dma_range_id
		# TODO: Set protection and interrupts
		dma_range_id
	
	unpage_range: (start, end) ->
		dma_range_id = @remove_range start, end
		return false  unless dma_range_id
		# TODO: Remove protection and interrupts
		dma_range_id
	
	# Private API.

	stat: (stat, increment) ->
		@stats[stat] = @stats[stat] || 0
		@stats[stat] += increment

	# Reset the head page location.
	# Subsequent memory operations are highly likely to occur on the current
	# page, thus we save the head position and use that as a starting point
	# for all subsequent lookups.
	reset_head: (location) ->
		@head = @select location, @head
	
	select: (location, PagingNode) ->
		if location >= PagingNode.start &&
		   location <= PagingNode.start + PagingNode.range
			return PagingNode
		else if location < PagingNode.start
			# Prev page not exist or too low? Insert page
			if !PagingNode.prev ||
			   location > (PagingNode.prev.start + PagingNode.prev.range)
				@allocate location, PagingNode
			@select location, PagingNode.prev
		else
			# Next page not exist or too high? Insert page
			if !PagingNode.next || location < PagingNode.next.start
				@allocate location, PagingNode
			@select location, PagingNode.next
	
	allocate: (location, FromNode) ->
		node = new Pages.PagingNode @align(location), @pageSize, @implementation
		@stat PGSTATS_PAGES_ALLOCATED, +1
		return node unless FromNode

		if location < FromNode.start
			node.next = FromNode
			node.prev = FromNode.prev
			FromNode.prev = node
		else
			node.next = FromNode.next
			node.prev = FromNode
			FromNode.next = node
		node

	align: (offset) ->
		sign = 0
		if offset < 0
			sign = -1
			offset = -offset

		if offset % @pageSize != 0
			offset -= offset % @pageSize

		return -offset - @pageSize if sign
		return offset
	
	# DMA feature overrides
	dma_read: (loc, cpu) ->
		result = @read loc
		vlog 70, "Paging.lanes[#{@dma_id}].dma_read(#{loc}) = #{result}"
		result
	
	dma_write: (loc, value, cpu) ->
		result = @write loc, value
		vlog 70, "Paging.lanes[#{@dma_id}].dma_write(#{loc}, #{value}) = #{result}"
		result
exports.Paging = Paging

PageTest = () ->
	{charCode} = require 'tc_util'
	offset = 0xFF
	paging = new Paging

	while offset < 0xFFFFFFFF
		paging.write offset + 0, charCode('H')
		paging.write offset + 1, charCode('e')
		paging.write offset + 2, charCode('l')
		paging.write offset + 3, charCode('l')
		paging.write offset + 4, charCode('o')
		if paging.read(offset + 0) != charCode('H') ||
		paging.read(offset + 1) != charCode('e') ||
		paging.read(offset + 2) != charCode('l') ||
		paging.read(offset + 3) != charCode('l') ||
		paging.read(offset + 4) != charCode('o')
			return "failure at #{offset}"
		offset *= 10
	offset = -0xFF
	while offset > -0xFFFFFF
		paging.write offset + 0, charCode('H')
		paging.write offset + 1, charCode('e')
		paging.write offset + 2, charCode('l')
		paging.write offset + 3, charCode('l')
		paging.write offset + 4, charCode('o')
		if paging.read(offset + 0) != charCode('H') ||
		paging.read(offset + 1) != charCode('e') ||
		paging.read(offset + 2) != charCode('l') ||
		paging.read(offset + 3) != charCode('l') ||
		paging.read(offset + 4) != charCode('o')
			return "failure at #{offset}"
		offset *= 10
	stats = paging.get_stats()
	console.log "Pages allocated: ", stats[PGSTATS_PAGES_ALLOCATED]
	'pass'

if process.env.TCPU_PAGE_TEST
	console.log "Paging test: ", PageTest()

module.exports = exports