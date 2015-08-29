# Verbosity-based logging
#
# Provides a simple level-based verbosity logging to standard output.

{decSymbol} = require('symbols')

SETTINGS_VERB = decSymbol 'SETTINGS_VERB', 'verbosity'
settings = {}

vlog = () ->
	# First is verbosity level
	args = Array.prototype.slice.call(arguments)

	verbosity = args.shift()
	if settings[SETTINGS_VERB] >= verbosity
		args.unshift("(V-" + verbosity + ")")
		console.log.apply(console, args)
		true
	false

exports = module.exports =
	vlog: vlog
	setVerbosity: (v) -> settings[SETTINGS_VERB] = v
	getVerbosity: ()  -> settings[SETTINGS_VERB] || 0

exports.setVerbosity(process.env.TINY_VERB || 10)
