# Concur is an object-based virtual machine which incorporates a lightweight
# thread model for natural concurrency.
#
# It is designed to be easily portable to other languages and implementations.
# Part of this design is the limitation of a single CPU thread. SMP and
# multithreadedness is achieved using multiple Concur instances communicating
# with each other over a transport protocol.
#
# The transport protocol is also designed for portability, including the
# transport of functions and programs between remote Concur instances.
#

# A lightweight process, with details on starting module and function.
# Includes a local process id (lpid) and a remote process id (rpid) - the lpid
# can be used by local processes, whilst the rpid must be used for anything
# running on a remote instance.
class ConcurProcess
	constructor: (Options) ->
		{@lpid, @rpid, @init_module, @init_fun, @init_args} = Options
		@stack = []
		@stack.push new ConcurStack(
			module: @init_module,
			fun: @init_fun,
			args: @init_args,
			process: @
		)
		@messages = []
		@memory = {}
		
class ConcurStack
	constructor: (Options) ->
		{@module, @fun, @args, @process, @parent} = Options
		@state = {}
		@cp = 0

	# After duplication, the stack can be applied to a different process.
	duplicate: () ->
		cs = new ConcurStack
		cs.module = @module
		cs.fun = @fun
		cs.args = @args
		cs.process = @process
		cs.state = @state
		cs.cp = @cp
		cs

# The Virtual Execution Unit
# Runs precompiled bytecode.
class ConcurVEU