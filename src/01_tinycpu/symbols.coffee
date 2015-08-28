# Symbols defined by features are stored here.
definition_cache = {}

# Define a symbol. Throws exception if already exists.
defSymbol = (name, value) ->
	throw "symbol already registered" if name in definition_cache
	definition_cache[name] = value

# Declare a symbol. No exception thrown if exists and same value.
decSymbol = (name, value) ->
	throw "redefinition of #{name} to #{value}" if name in definition_cache and definition_cache[name] != value
	definition_cache[name] = value

getSymbol = (name) -> definition_cache[name]
getSymbols = () -> definition_cache

exports = module.exports =
	defSymbol: defSymbol
	decSymbol: decSymbol
	getSymbol: getSymbol
	getSymbols: getSymbols