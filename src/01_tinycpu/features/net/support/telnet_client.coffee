# Provides a basic Telnet client interface
#

{Events} = require 'util/events'
{clone, SuperClass} = require 'tc_util'
{decSymbol} = require 'symbols'
{vlog} = require 'verbosity'

telnet_client_types = {}

class TelnetClient extends SuperClass
	@include Events

	constructor: () ->
		Events.call @
		vlog 50, "TelnetClient constructor, registering events"
		@event 'open', "When the connection opens"
		@event 'data', "When a command is received from the client"
		@event 'close', "When a client disconnects"
		@event_delayed_binding 'open'

	write: () ->
		vlog 20, "WARN: TelnetClient.write STUB"
		return
	close: () ->
		vlog 20, "Closing a TelnetClient"
		@fire 'close'
		return
exports.TelnetClient = decSymbol 'TelnetClient', TelnetClient
telnet_client_types[''] = TelnetClient

class StreamTelnetClient extends SuperClass
	@include TelnetClient

	constructor: (@stream) ->
		vlog 50, "CALLING SUPER"
		TelnetClient.call @
		vlog 50, "BACK FROM SUPER"

		vlog 30, "New StreamTelnetClient"
		@stream_closed = false

		self = @
		stream.on 'data', (data) ->
			data = data.toString()
			vlog 50, "TelnetClient got data: ", data
			self.fire 'data', data
			return
		stream.on 'close', () ->
			vlog 50, "TelnetClient: stream closed"
			self.stream_closed = true
			self.fire 'close'
			return
		@on 'close', () ->
			stream.destroy()
			return
		@fire 'open', stream

	write: (data) ->
		if !@stream_closed
			@stream.write data
		else
			vlog 50, "Lost #{data.length} characters due to closed stream"
		return
exports.StreamTelnetClient = decSymbol 'StreamTelnetClient', StreamTelnetClient
telnet_client_types['stream'] = StreamTelnetClient

class BufferTelnetClient extends TelnetClient
	constructor: (@buffer) ->
		self = @
		@closed = false
		@buffer.on 'flush', (data) ->
			vlog 50, "BufferTelnetClient got data: ", data
			self.fire 'data', data
		super
		@fire 'open', @buffer
	
	write: (data) ->
		if !@closed
			@buffer.write_string data
			@buffer.flush()
		else
			vlog 50, "Lost #{data.length} characters due to closed buffer"
		return
exports.BufferTelnetClient = decSymbol 'BufferTelnetClient', BufferTelnetClient
telnet_client_types['buffer'] = BufferTelnetClient

exports.getTelnetClient = (type) -> telnet_client_types[type]
exports.getTelnetClientTypes = () -> clone telnet_client_types

decSymbol 'TelnetClient.Types', telnet_client_types

module.exports = exports
