fs     = require 'fs'
{spawn, exec} = require 'child_process'

typeIsArray = Array.isArray || (value) -> return {}.toString.call(value) is '[object Array]'

debugLevel = process.env.CAKE_VERB || 10
debug = () ->
	args = Array.prototype.slice.call(arguments)
	level = args.shift()
	if level <= debugLevel
		console.log.apply(console, args)

# Source file definitions
# Key is path, with subkeys inheriting the parent path.
# The value is either another hash (path continuation), or filespec array.
# '' is used to denote no new path.
appFiles =
	'01_tinycpu':
		'': ['tinycpu', 'verbosity']
		'features':
			'': ['feature', 'dma', 'buffer']
			interrupts: ['interrupt']
			io: ['stdio']
			watchers: ['halt']
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

task 'build_app', 'Build single application file from source files', ->
  appContents = new Array remaining = appFiles.length
  for file, index in appFiles then do (file, index) ->
    fs.readFile "src/#{file}.coffee", 'utf8', (err, fileContents) ->
      throw err if err
      appContents[index] = fileContents
      process() if --remaining is 0
  process = ->
    fs.writeFile 'app.coffee', appContents.join('\n\n'), 'utf8', (err) ->
      throw err if err
      exec 'coffee --compile app.coffee', (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
        fs.unlink 'app.coffee', (err) ->
          throw err if err
          console.log 'Done.'

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
	node_path = "src/01_tinycpu"
	init_path = "src/01_tinycpu/tests/features"
	p = spawn "node", [init_path],
		env:
			NODE_PATH: node_path
			TINY_VERB: process.TINY_VERB || 0
		stdio: [0, 1, 2]
	console.log("Node starting up", p)
	p.on 'exit', (code) ->
		console.log("Node quit (", code, "), finishing")
		process.exit(code)

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
