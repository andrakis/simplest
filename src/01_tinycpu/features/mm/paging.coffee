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
{vlog} = require 'verbosity'

PAGE_DEFAULT_SIZE = decSymbol 'PAGE_DEFAULT_SIZE', 32 * 1024

# This is the worker implementation, ie the class that performs the actual
# reading and writing for a page.
# New implementations can be created by extending this class and passing it
# to the Paging class instance.
class PageImplementation
	constructor: () ->
		@init()

	# Public API. You are discouraged from altering these.
	read: (location) -> @do_read location
	write: (location, value) -> @do_write location, value

	# Overridable API. Extending classes should implement their own versions
	# of the following functions.

	# Called upon construction
	init: () ->
		vlog 50, 'PageImplementation.init: base implementation'
		@memory = {}
	
	# Perform a read operation
	do_read: (location) ->
		vlog 50, 'PageImplementation.do_read: base implementation'
		@memory[location] || 0
	
	# Perform a write operation
	do_write: (location, value) ->
		vlog 50, 'PageImplementation.do_write: base implementation'
		@memory[location] = value || 0

PagingImplementations =
	Default: PageImplementation

class PagingOptions
	constructor: (Options) ->
		@PageSize = Options.PageSize || PAGE_DEFAULT_SIZE
		# Name of entry in PagingImplementations
		@PageImplementation = 'Default'
	
	getPageImplementation: (name) ->
		x = PagingImplementations[name || @PageImplementation]
		new x

options = new PagingOptions

class Page
	constructor: (pageSize, implementation) ->
		@pageSize = pageSize || PAGE_DEFAULT_SIZE
		@implementation = options.getPageImplementation implementation
	
	read: (location) -> @implementation.read location
	write: (location, value) -> @implementation.write location, value

class PagingNode
	constructor: (start, range, implementation) ->
		@start = start
		@range = range
		@implementation = implementation
		@prev = null
		@next = null
		@page = new Page range, @implementation

class Paging
	constructor: (Options) ->
		{@pageSize, @implementation} = Options
		@pageSize = @pageSize || options.PageSize
		@implementation = @implementation || options.PageImplementation
		@head = @allocate 0
	
	# Public API.
	
	read: (location) ->
		@reset_head location
		@head.read location - @head.start
	
	write: (location, value) ->
		@reset_head location
		@head.write location - @head.start, value
	
	# Private API.

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
				PagingNodeAllocate location, PagingNode
			@select location, PagingNode.next
	
	allocate: (location, PagingNode) ->
		node = new PagingNode memAlign(location), @pageSize, @implementation
		return node unless PagingNode

		if location < Page.start
			node.next = Page
			node.prev = Page.prev
			Page.prev = node
		else
			node.next = Page.next
			node.prev = Page
			Page.next = node
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

PageTest = () ->
	{charCode} = require 'tc_util'
	offset = 0xFF
	paging = new Paging

	while offset < 0xFFFFFFFF
		paging.write offset + 0, charCode('H'), mem
		paging.write offset + 1, charCode('e'), mem
		paging.write offset + 2, charCode('l'), mem
		paging.write offset + 3, charCode('l'), mem
		paging.write offset + 4, charCode('o'), mem
		if paging.read(offset + 0, mem) != charCode('H') ||
		paging.read(offset + 1, mem) != charCode('e') ||
		paging.read(offset + 2, mem) != charCode('l') ||
		paging.read(offset + 3, mem) != charCode('l') ||
		paging.read(offset + 4, mem) != charCode('o')
				return offset
		offset *= 10
	offset = -0xFF
	while offset > -0xFFFFFF
		paging.write offset + 0, charCode('H'), mem
		paging.write offset + 1, charCode('e'), mem
		paging.write offset + 2, charCode('l'), mem
		paging.write offset + 3, charCode('l'), mem
		paging.write offset + 4, charCode('o'), mem
		if paging.read(offset + 0, mem) != charCode('H') ||
		paging.read(offset + 1, mem) != charCode('e') ||
		paging.read(offset + 2, mem) != charCode('l') ||
		paging.read(offset + 3, mem) != charCode('l') ||
		paging.read(offset + 4, mem) != charCode('o')
			return offset
		offset *= 10
	0

if process.env.TCPU_PAGE_TEST
	console.log "Paging test: ", PageTest()