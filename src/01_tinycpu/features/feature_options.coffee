# Provides an interface for getting and setting feature options.
#
# Feature options can hook into a webpage for interactive options.

class FeatureOption
	constructor: (name, _default) ->
		@name = name
		@value = @default = _default
		@binds = {}
	
	export: (res) ->
		res = res || {}
		res[@name] = @value
		res
	
	getValue: () -> @value
	setValue: (value) ->
		res = @fire_bind 'set', @value, value
		@value = res

	bind: (event, callback) ->
		@binds[event] = @binds[event] || []
		@binds[event].push callback
		true
	fire_bind: (event, old_value, new_value) ->
		return new_value  if @binds[event] == undefined

		res = new_value

		for callback in @binds[event]
			next_res = callback new_value, old_value
			res = next_res  if next_res != undefined

		res

	createHtml: (jQuery) ->
		jQuery "<span class='option'>There are no options for this feature</span>"
	createContainer: (jQuery) ->
		jQuery "<span class='option' />"
	createLabel: (text, childElements, jQuery) ->
		label = jQuery "<label/>"
		label.text text
		return label  unless childElements?
		childElements = [childElements] if typeof childElements != []
		for ele in childElements
			label.append childElements
		label
	createInput: (jQuery) ->
		jQuery "<input class='option' />"

exports.FeatureOption = FeatureOption

class StringOption extends FeatureOption
	constructor: (name, _default) ->
		super name, _default
	
	createHtml: (jQuery) ->
		input = @createInput jQuery
		self = @

		input.change () ->
			self.setValue jQuery(@).attr 'value'
			return

		@createContainer().append @createLabel(@name, input, jQuery)
exports.StringOption = StringOption

class IntegerOption extends FeatureOption
	constructor: (name, _default, options) ->
		super name, _default
		options = options || {}
		@min = options.min || NaN
		@max = options.max || NaN
	
	createHtml: (jQuery) ->
		input = @createInput jQuery
		input.attr 'type', 'number'

		input.change () ->
			self.setValue jQuery(@).attr 'value'

		@createContainer().append @createLabel(@name, input, jQuery)
exports.IntegerOption = IntegerOption

class IntegerRangeOption extends IntegerOption
	constructor: (name, start, end) ->
		super name, @makeRange(start, end)

	makeRange: (start, end) -> [start, end]

	createHtml: (jQuery) ->
		start = super jQuery
		end   = super jQuery

		start.unbind 'change'
		end.unbind 'change'

		self = @

		change = () ->
			self.setValue [start.attr 'value', end.attr 'value']

		container = @createContainer()
		container.append @createLabel('Start', start, jQuery)
		container.append @createLabel('End', end, jQuery)
		container
exports.IntegerRangeOption = IntegerRangeOption

class FeatureOptionStub extends FeatureOption
	constructor: (name, _default, message) ->
		super name, _default
		@message = message
	
	createHtml: (jQuery) ->
		message = @message || "#{name} cannot be set via this method"
		@createContainer().append @createLabel(music, null, jQuery)
exports.FeatureOptionStub = FeatureOptionStub

module.exports = exports
