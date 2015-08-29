# Support classes for the paging feature.

{vlog} = require 'verbosity'
{decSymbol} = require 'symbols'
{clone} = require 'tc_util'

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

PageImplementations = {}

exports.RegisterPageImplementation = (name, cls) -> PageImplementations[name] = cls
exports.GetPageImplementations = () -> clone(PageImplementations)

exports.RegisterPageImplementation 'Default', PageImplementation

class PagingOptions
	constructor: (Options) ->
		Options = Options || {}
		@PageSize = Options.PageSize || PAGE_DEFAULT_SIZE
		# Name of entry in PagingImplementations
		@PageImplementation = 'Default'
	
	getPageImplementation: (name) ->
		x = PageImplementations[name || @PageImplementation]
		new x
exports.PagingOptions = PagingOptions

class Page
	constructor: (pageSize, implementation) ->
		@pageSize = pageSize || options.PageSize
		@implementation = options.getPageImplementation implementation
	
	read: (location) -> @implementation.read location
	write: (location, value) -> @implementation.write location, value
exports.Page = Page

class PagingNode
	constructor: (start, range, implementation) ->
		@start = start
		@range = range
		@implementation = implementation
		@prev = null
		@next = null
		@page = new Page range, @implementation
	
	read: (location) -> @page.read location
	write: (location, value) -> @page.write location, value
exports.PagingNode = PagingNode

options = new PagingOptions
exports.options = options

module.exports = exports

decSymbol 'Paging.support.pages', exports