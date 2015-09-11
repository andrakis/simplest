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

	# Define a fireable event.
	event: (name, description) ->
		throw "Event #{name} already registered" if @events_info[name]?
		@events_info[name] = description
		vlog 50, "Event #{name} registered: #{description}"
		return

	# Flags an event for delayed binding. In this mode, the event firings
	# are tracked, and fired the first time the event is bound.
	event_delayed_binding: (name) ->
		@events_pending[name] = @events_pending[name] || []
		vlog 50, "Delayed binding for #{name}"
		return

	# Attach a callback to an event.
	on: (event, callback) ->
		@events[event] = @events[event] || []
		@events[event].push callback
		@_fire_pending event, callback
		return

	# Fire an event
	# Usage: fire 'event', arg1, arg2, ...
	fire: () ->
		args = Array.prototype.slice.call arguments
		event = args.shift()
		throw 'event required'  if !event

		vlog 50, "Events.fire(#{event}, ...)"

		if @events_pending[event]?
			vlog 50, "Pushing a pending event for later firing"
			@events_pending[event].push args

		callbacks = @events[event] || []
		for cb in callbacks
			@_fire_callback event, cb, args
		return
	
	_fire_pending: (event, callback) ->
		pending = @events_pending[event] || []
		vlog 50, "Pending callbacks for #{event}:", pending
		for args in pending
			@_fire_callback event, callback, args
		@events_pending[event] = []
		return
	_fire_callback: (event, callback, args) ->
		# TODO: should context be something useful?
		context = {}
		vlog 80, "Firing callback for #{event}"
		callback.apply context, args
		return

exports.Events = Events
module.exports = exports
