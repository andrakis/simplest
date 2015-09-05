fs      = require 'fs'
{print} = require 'util'
{spawn, exec} = require 'child_process'

extend = exports.extend = (object, properties) ->
	for key, val of properties
		object[key] = val
	object
clone = (obj) ->
	return obj  if obj is null or typeof (obj) isnt "object"
	temp = new obj.constructor()
	for key of obj
		temp[key] = clone(obj[key])
	temp
typeIsArray = Array.isArray || (value) -> return {}.toString.call(value) is '[object Array]'

debugLevel = process.env.CAKE_VERB || 10
debug = () ->
	args = Array.prototype.slice.call(arguments)
	level = args.shift()
	args.unshift "(#{level})"
	if level <= debugLevel
		console.log.apply(console, args)

# Source file definitions
# Key is path, with subkeys inheriting the parent path.
# The value is either another hash (path continuation), or filespec array.
# '' is used to denote no new path.
appFiles =
	'01_tinycpu':
		'': ['symbols', 'tc_util', 'verbosity', 'tinycpu']
		#'a_assembler': ['tca']
		'features':
			'': ['feature', 'dma', 'buffer']
			interrupts: ['interrupt']
			io: ['bitmask', 'stdio']
			mm:
				support: ['pages']
				'': ['paging']
			watchers: ['flags', 'halt']
		'tests':
			'': ['features']
	'02_concur':
		lib: ['concur']
	
# Flatten appFiles into standard array
translate = (files, pathAcc) ->
	path = pathAcc || []
	appFiles = []
	debug(50, "translate(", '...', ", ", path, ")")
	for filespec, targets of files
		if typeIsArray(targets)
			path.push(filespec) if filespec != ''
			total_path = path.join('/')
			debug(50, "Targets is array", targets, "total_path: ", total_path)
			for target in targets
				appFiles.push(total_path + "/" + target)
			path.pop() if filespec != ''
		else
			if targets != ''
				if typeof targets == typeof {}
					debug(50, "Recursing with directory, x=", filespec)
					path.push(filespec)
					appFiles = appFiles.concat(translate(targets, path))
					path.pop()
				else if typeof targets == typeof ""
					debug(50, "Pushing path: ", targets)
					path.push targets
	appFiles

appFiles = translate(appFiles)
debug(10, appFiles)

moduleWrap = undefined
getModuleWrap = (callback) ->
	if moduleWrap?
		return callback moduleWrap

	fs.readFile "src/wrap.js", 'utf8', (err, wrap) ->
		throw err if err
		fs.readFile "src/wrap_post.js", 'utf8', (err2, wrap_post) ->
			throw err2 if err2
			moduleWrap = (definitions, content) ->
				debug 70, "wrapping module, definitions are", definitions
				full = "#{wrap}\n#{content}\n#{wrap_post}"
				rewrite_definitions full, definitions
			callback moduleWrap
rewrite_definitions = (content, definitions) ->
	for key, value of definitions
		debug 70, "  #{key} => #{value}"
		regex = new RegExp "([^A-Za-z0-9_]*)#{key}([^A-Za-z0-9])", 'g'
		content = content.replace regex, "$1#{value}$2"
	content

wrapModule = (definitions, contents, callback) ->
	getModuleWrap (wrap) ->
		callback wrap(definitions, contents)

default_definitions =
	__verbose__: 0

task 'build_app', 'Build single application file from source files', ->
  # Prepend the app_boot.coffee file
	appContents = new Array
	remaining = appFiles.length
	appJs = []
	for file, index in appFiles then do (file, index) ->
		fs.readFile "src/#{file}.coffee", 'utf8', (err, fileContents) ->
			debug 30, "got contents for #{file}.coffee, length: #{fileContents.length}"
			# Run some substitutions
			# Remove first directory name
			fixedFilePath = file.replace /^.*?\//, ''
			definitions = extend clone(default_definitions),
				__file__: fixedFilePath
			appContents[index] =
				file: file
				content: fileContents
				definitions: definitions
			process() if --remaining is 0
	process = ->
		debug 60, "process()"
		next()
	finish = ->
		debug 60, "finish()"
		# Get the app wrappers
		fs.readFile 'src/app_wrapper.js', 'utf8', (err, app_wrapper) ->
			throw err if err
			appJs.unshift rewrite_definitions app_wrapper, default_definitions
			fs.readFile 'src/app_wrapper_post.js', 'utf8', (err, app_wrapper_post) ->
				throw err if err
				appJs.push rewrite_definitions app_wrapper_post, default_definitions
				fs.writeFile 'app.js', appJs.join("\n\n"), 'utf8', (err) ->
					throw err if err
					console.log 'Done.'
	next = ->
		debug 60, "next()"
		return finish() if appContents.length == 0
		{file, content, definitions} = appContents.shift()
		debug 50, "writing intermediate"
		fs.writeFile 'intermediate.coffee', content, 'utf8', (err) ->
			debug 50, "got contents, spawning coffee for #{file}"
			throw err if err
			exec 'coffee --compile intermediate.coffee', (err, stdout, stderr) ->
				debug 90, "coffee result got: #{err}"
				throw err if err
				print "."
				debug 50, stdout + stderr
				fs.unlink 'intermediate.coffee', (err) ->
					debug 60, "unlink intermediate ok"
					throw err if err
					fs.readFile 'intermediate.js', 'utf8', (err, fileContents) ->
						debug 60, "intermediate.js: #{fileContents.length}"
						throw err if err
						fs.unlink 'intermediate.js', (err) ->
							throw err if err
							debug 90, "unlink ok"
							wrapModule definitions, fileContents, (result) ->
								debug 50, "wrapModule got result: #{result.length}"
								appJs.push result
								next()
							return

task 'build', 'Build source files', ->
	# Prefix appFiles
	pAppFiles = for file in appFiles
		"src/#{file}"
	console.log "Compiling: ", pAppFiles.join(', ')
	exec 'coffee --compile ' + pAppFiles.join(' '), (err, stdout, stderr) ->
		throw err if err
		console.log stdout + stderr

task 'watch', 'Watch files for changes', ->
	coffee = spawn 'coffee', ['-w', '-c', 'src']
	coffee.stderr.on 'data', (data) ->
		process.stderr.write data.toString()
	coffee.stdout.on 'data', (data) ->
		print data.toString()

task 'run', 'Run test feature', ->
	run_node "src/01_tinycpu/tests/features", "src/01_tinycpu",
		TINY_VERB: process.TINY_VERB || 0

task 'run_verbose', 'Run test feature with full verbosity', ->
	run_node "src/01_tinycpu/tests/features", "src/01_tinycpu",
		TINY_VERB: 100

task 'run_app', 'Run the compiled app.js version of the test feature', ->
	run_node "app", "", {}

task 'test_paging', 'Test the paging functionality', ->
	run_node "src/01_tinycpu/features/mm/paging", "src/01_tinycpu",
		TCPU_PAGE_TEST: 1
		
# Make sure we only run one at a time
node_queue = []
node_running = false
run_next_node = () ->
	next = node_queue.shift()
	if next
		console.log "Instantiating next node"
		instantiate_node next, run_next_node
	else
		console.log "Node processes finished, exiting"
		process.exit 0

run_node = (entry, lib_path, env) ->
	node_queue.push
		entry: entry
		lib_path: lib_path
		env: env
	run_next_node()  unless node_running

instantiate_node = (options, finish_callback) ->
	{entry, lib_path, env} = options
	env['NODE_PATH'] = lib_path
	node_running = true
	p = spawn "node", [entry],
		env: env
		stdio: [0, 1, 2]
	console.log "Spawning: node #{entry}"
	p.on 'exit', (code) ->
		node_running = false
		console.log "Node quit (#{code})"
		return finish_callback()  if finish_callback

task 'clean', 'Clean compiled js files', ->
	jsFiles = []
	for file in appFiles
		jsFiles.push "src/#{file}.js"
	unlink = (file, next) ->
		console.log "unlink(", file, ")"
		fs.unlink(file, () -> 0)
		file = next.shift()
		unlink(file, next) if file
	unlink(jsFiles.shift(), jsFiles)
