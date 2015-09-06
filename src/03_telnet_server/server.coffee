# This is a simple telnet server for Node.js
#

net = require 'net'
{Buffer} = require 'features/buffer'
{Events} = require 'util/events'
{SuperClass} = require 'tc_util'

TELNET_VERB = 100
TELNET_SERVER_PORT = 8888

log = () ->
	args = Array.prototype.slice.call arguments
	level = args.shift()
	if level <= TELNET_VERB
		console.log.apply console, args
	return

clients = []
class TelnetClient extends SuperClass
	@include Events

	constructor: (stream) ->
		log 30, "New TelnetClient"
		Events.call @
		@stream = stream
		@stream_closed = false

		@event 'open', "When the connection opens"
		@event 'data', "When a command is received from the client"
		@event 'close', "When a client disconnects"

		self = @
		stream.on 'data', (data) ->
			data = data.toString()
			log 50, "TelnetClient got data: ", data
			self.fire 'data', data
			return
		stream.on 'close', () ->
			log 50, "TelnetClient: stream closed"
			@stream_closed = true
			self.fire 'close'
			return

		@event_delayed_binding 'open'
		@fire 'open', stream
	
	write: (data) ->
		if !@stream_closed
			@stream.write data
		else
			vlog 50, "Lost #{data.length} characters due to closed stream"
		return

# A telnet handling interface. Handles commands and responses.
# This is designed to work with any TelnetClient class.
class TelnetInterface extends SuperClass
	@include Events

	constructor: (client) ->
		Events.call @

		@commands = {}

		@client = client

		self = @

		client.on 'open', () -> self.on_open.apply self, arguments
		client.on 'data', () -> self.on_data.apply self, arguments
		client.on 'close', () -> self.on_close.apply self, arguments

		@command 'help', () ->
			@write "Available commands:\n"
			@write (cmd for own cmd of @commands).join ','
			@write "\n"

		@command 'shutdown', () ->
			@write "Requesting shutdown"
			setTimeout( ->
				server.close()
				server_socket.destroy()
			, 1)

		log 30, "New TelnetInterface"
	
	write: (data) -> @client.write data
	prompt: () -> @write "\n] "
	
	command: (name, regex, callback) ->
		throw "Command #{name} already defined"  if @commands[name]?
		if !callback && typeof regex == 'function'
			callback = regex
			regex = null
		else
			throw "Regex #{regex} already defined"  if @commands[regex]?
			@commands[regex] = callback
		@commands[name] = callback
		return

	on_open: (stream) ->
		@write "Welcome to the Simplest Telnet Server\n"
		@prompt()
		return
	on_data: (data) ->
		# Attempt to parse data
		data = data.toString()
		success = false
		isRegExpCheck = new RegExp(" RegExp\\(")
		for regex, callback of @commands
			isRegExp = regex.constructor.toString().match isRegExpCheck
			if typeof regex == 'string'
				match = data.match new RegExp("^#{regex}(?: )?(.*)?")
			else if isRegExp
				match = data.match(regex)
			else
				log 10, "WARN: unable to parse command", regex
				match = false
			break  if match
		if match
			success = true
			# Remove first element (regex full string match)
			match.shift()
			callback.apply @, match
		if !success
			@write "Unknown command\n"
		@prompt()
		return
	on_close: () ->

server_socket = undefined
server = net.createServer (stream) ->
	client = new TelnetClient stream
	int = new TelnetInterface client
server.on 'connection', (socket) -> server_socket = socket
server.listen TELNET_SERVER_PORT
console.log "Waiting for connection on port #{TELNET_SERVER_PORT}"
