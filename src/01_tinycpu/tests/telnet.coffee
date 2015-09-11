# Features test - Telnet / monitor
#
# This tests out telnet server functionality.

require 'coffee-script/register'
{Feature, GetFeatures} = require 'features/feature'
{Halt} = require 'features/watchers/halt'
{TinyCPU} = require 'tinycpu'
{vlog} = require 'verbosity'
symbols = require 'symbols'
{charCode, DumpObjectFlat} = require 'tc_util'
{TelnetServer} = require 'features/net/telnet'

TELNET_PORT = 8000

test = ( ->
	console.log "The available features are: ", (name for own name of GetFeatures())

	halted = false
	cpu = new TinyCPU
	cpu.enable_debug true

	(new Halt( ->
		halted = true
		vlog 20, "CPU halted"
	)).load_into cpu

	server = new TelnetServer TELNET_PORT
	server.load_into cpu
)

exports = module.exports =
	test: test

# Being run from node.js directly?
exports.test() if typeof modules == 'undefined' && process.env.RUN_TARGET == 'telnet'
