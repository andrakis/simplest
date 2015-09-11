# Verbosity-based logging
#
# Provides a simple level-based verbosity logging to standard output.

{decSymbol, hasSymbol, getSymbol} = require('symbols')
{DumpObjectFlat} = require 'tc_util'

SETTINGS_VERB = decSymbol 'SETTINGS_VERB', 'TINY_VERB'
settings = {}

my_parse_object = (obj) ->
	DumpObjectFlat obj

my_logger = () ->
	results = (my_parse_object arg for arg in arguments)
	console.log results.join(' ')

loggers = []
loggers.push
	logger: console.log
	context: console
if 1
	loggers.push
		logger: my_logger
		context: {}

vlog = () ->
	# First is verbosity level
	args = Array.prototype.slice.call(arguments)

	verbosity = args.shift()
	if getVerbosity() >= verbosity
		if verbosity > 0
			args.unshift("(V-" + verbosity + ")")
		# Demonstratably faster than x.slice(-1)
		# http://jsperf.com/slice-vs-length-1-arr
		logger = loggers[loggers.length - 1]
		logger.logger.apply logger.context, args
		true
	false

push_logger = (logger, context) ->
	loggers.push
		logger: logger
		context: context
	return

pop_logger = () ->
	loggers.pop()
	return

getVerbosity = () ->
	if hasSymbol(SETTINGS_VERB)
		return getSymbol SETTINGS_VERB
	settings[SETTINGS_VERB]

exports = module.exports =
	vlog: vlog
	setVerbosity: (v) -> settings[SETTINGS_VERB] = v
	getVerbosity: ()  -> settings[SETTINGS_VERB] || 0

exports.setVerbosity(process.env.TINY_VERB || 10)
