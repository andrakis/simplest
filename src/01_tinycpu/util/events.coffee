# TinyCPU Util class - Events
#
# Events can be added to any class that inherits SuperClass.
# All features extend SuperClass.
#
# See tc_util::SuperClass for invocation.
{vlog} = require 'verbosity'
{SuperClass} = require 'tc_util'

class Events extends SuperClass
	constructor: () ->
		@events = {}
		@events_info = {}
		@events_pending = {}

	event: (name, description) ->
		throw "Event #{name} already registered" if @events_info[name]?
		@events_info[name] = description

	# Flags an event for delayed binding. In this mode, the event firings
	# are tracked, and fired the first time the event is bound.
	event_delayed_binding: (name) ->
		@events_pending[name] = @events_pending[name] || []
		return

	on: (event, callback) ->
		@events[event] = @events[event] || []
		@events[event].push callback
		@_fire_pending event, callback
		return
	
	# Usage: fire 'event', arg1, arg2, ...
	fire: () ->
		args = Array.prototype.slice.call arguments
		event = args.shift()
		throw 'event required'  if !event

		if @events_pending[event]?
			@events_pending[event].push args

		callbacks = @events[event] || []
		for cb in callbacks
			@_fire_callback cb, args
		return
	
	_fire_pending: (event, callback) ->
		pending = @events_pending[event] || []
		for args in pending
			@_fire_callback callback, args
		@events_pending[event] = []
		return
	_fire_callback: (callback, args) ->
		# TODO: should context be something useful?
		context = {}
		callback.apply context, args
		return

exports.Events = Events
module.exports = exports
