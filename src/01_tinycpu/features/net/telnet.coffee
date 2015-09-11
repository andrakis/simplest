# Provides a telnet server for TinyCPU.
#
# Also provides a standard telnet interface that can be extended to
# provide additional commands.
#

net = require 'net'
{Buffer} = require 'features/buffer'
{Events} = require 'util/events'
{SuperClass, removeArrayItem} = require 'tc_util'
{decSymbol, getSymbol, setSymbol, getSymbols} = require 'symbols'
{StreamTelnetClient} = require 'features/net/support/telnet_client'
{Feature} = require 'features/feature'
{vlog} = require 'verbosity'

TELNET_VERB = decSymbol 'TELNET_VERB', 20
TELNET_SERVER_PORT = decSymbol 'TELNET_SERVER_PORT', 8888

# TODO: Move this elsewhere
hook_writestream = (stream, callback) ->
  old_write = stream.write
  stream.write = ((write) ->
    (string, encoding, fd) ->
      write.apply stream, arguments
      callback string, encoding, fd
      return
  )(stream.write)
  ->
    stream.write = old_write
    return

# A telnet handling interface. Handles commands and responses.
# This is designed to work with any TelnetClient class.
class TelnetInterface extends SuperClass
	@include Events

	constructor: (@client) ->
		Events.call @

		vlog 50, "TelnetInterface with client: #{@client}"

		self = @
		@event 'command', 'When the client invokes a command'
		@event 'disconnect', 'When the client disconnects'

		# Listen to our own event to fire it
		@on 'command', (regex, callback, args) ->
			callback.apply self, args

		@commands = {}

		client.on 'open', () -> vlog 100, 'open'; self.on_open.apply self, arguments
		client.on 'data', () -> vlog 100, 'data'; self.on_data.apply self, arguments
		client.on 'close', () -> vlog 100, 'close'; self.on_close.apply self, arguments
		@command 'help', () ->
			@write "Available commands:\n"
			@write (cmd for own cmd of @commands).join ', '
			@write "\n"
			return

		@command 'set', /^(?:set|export)? ??([A-Z_$]+)\s*=\s*(.*)$/, (name, value) ->
			if name? and value?
				was = setSymbol name, value
				@write "#{name} set to '#{value}' (was: '#{was}')\n"
				return
			@write "usage: set    env_name=env_value\n"
			@write "       export env_name=env_value\n"
			return

		@command 'get', /^(?:get) ?([A-Z_$]+)?$/, (name) ->
			if name?
				@write "Value of #{name} is '#{getSymbol name}'\n"
				return
			@write "usage: get env_name\n"
			return

		@command 'env', /^env(?: ([A-Za-z_]+)\s*(?:=\s*(.*))?)?/, (name, value) ->
			if name? and value?
				prev = process.env[name]
				process.env[name] = value
				@write "#{name} => #{value} (was: #{prev})\n"
				return
			else if name?
				@write "#{name} = #{process.env[name]}\n"
				return
			@write "usage: env [name] [= value]"
			return

		@command 'attach', /^attach ?(stdout)?/, (stream) ->
			if stream?
				s = process[stream]
				if s?
					self = @
					hook_writestream process[stream], (data) ->
						str = data.toString()
						if !str.match /(\r|\n)$/
							str += "\n"
						self.write "(Rmt) #{str}"
					@write "Attached to stream #{stream}\n"
				else
					@write "Couldn't find stream #{stream}\n"
				return
			@write "usage: attach stream_name\n"
			@write "              stream_name is one of stdout, stderr, stdin"
			return

		@command 'test', () ->
			@write "Invoking features test\n"
			require('tests/features').test()
			@write "Test complete\n"
			return

		@command 'shutdown', () ->
			@write "Requesting shutdown"
			setTimeout( ->
				server.close()
				server_socket.destroy()
			, 1)
			return

		@isRegExpCheck = new RegExp(" RegExp\\(")
		vlog 30, "New TelnetInterface"
	
	write: (data) ->
		#vlog 80, "Write data to client: #{data}"
		@client.write data
	prompt: () -> @write "\n] "
	
	command: (name, regex, callback) ->
		throw "Command #{name} already defined"  if @commands[name]?
		if !callback && typeof regex == 'function'
			callback = regex
			regex = null
		if regex == null
			regex = new RegExp("^#{name}(?: )?(.*)?")
		@commands[name] =
			regex: regex
			callback: callback
		vlog 40, "Command #{name} registered"
		return
	additional_commands: (commands) ->
		for name, details in commands
			@command name, details.regex, details.callback
		return

	on_open: (stream) ->
		@write "Welcome to the Simplest Telnet Server\n"
		@write "Type help for a list of commands\n"
		@prompt()
		return
	on_data: (data) ->
		vlog 50, "on_data: #{data}"
		# Attempt to parse data
		data = data.toString()

		# Commands separated by \n
		lines = data.match /^(.*)?(?:\r|$)?/gm
		lines = lines.filter (line) -> line != ""
		vlog 50, "Lines: ", lines
		for line in lines
			line = line.trim()
			success = @on_entry line
			if !success
				@write "Unknown command\n"
		@prompt()
		return
		
	on_entry: (line) ->
		success = false
		vlog 80, "Commands are:", @commands
		for name, details of @commands
			vlog 80, "kv = #{name}, #{details}"
			regex = details.regex
			callback = details.callback
			vlog 80, "regex is #{regex}"
			match = line.match(regex)
			vlog 80, "Check #{line} to (regex) #{regex}, = #{match}"
			break  if match
		if match
			success = true
			# Remove first element (regex full string match)
			vlog 50, "Match is", match
			match.shift()
			vlog 50, "Match is", match
			@fire 'command', regex, callback, match
		success
	on_close: () ->
		@fire 'disconnect', @, @client
		return
exports.TelnetInterface = TelnetInterface
decSymbol 'TelnetInterface', 'TelnetInterface'

# This is a base class that needs to be extended for anything useful
# to occur.
# Alternatively, the code instantiating the telnet server could add
# commands dynamically to the interface via .addCommand
class TelnetServer extends Feature
	@include Events

	constructor: (@port) ->
		Events.call @

		@event 'connect', 'When a client connects'
		@event 'disconnect', 'When a client disconnects'

		@additional_commands = {}

		self = @
		@clients = []
		@server_socket = undefined
		@server = net.createServer (stream) ->
			client = new StreamTelnetClient stream
			int = new TelnetInterface client
			int.additional_commands self.additional_commands
			self.clients.push client

			int.on 'disconnect', (int, client) ->
				removeArrayItem self.clients, client
			return
		@server.on 'connection', (socket) -> self.server_socket = socket
		@server.listen @port
		super 'TelnetServer'
		vlog 0, "Waiting for connection on port #{@port}"

	addCommand: (name, regex, callback) ->
		throw "addCommand: #{name} already registered"  if @additional_commands[name]?
		@additional_commands[name] =
			regex: regex
			callback: callback
		return

exports.TelnetServer = TelnetServer
decSymbol 'TelnetServer', TelnetServer

module.exports = exports
