fs     = require 'fs'
{spawn, exec} = require 'child_process'

typeIsArray = Array.isArray || (value) -> return {}.toString.call(value) is '[object Array]'

# omit src/ and .coffee to make the below lines a little shorter
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
	console.log("translate(", '...', ", ", path, ")")
	for filespec, targets of files
		if typeIsArray(targets)
			path.push(filespec) if filespec != ''
			total_path = path.join('/')
			console.log("Targets is array", targets, "total_path: ", total_path)
			for target in targets
				appFiles.push(total_path + "/" + target)
			path.pop() if filespec != ''
		else
			if targets != ''
				if typeof targets == typeof {}
					console.log("Recursing with directory, x=", filespec)
					path.push(filespec)
					appFiles = appFiles.concat(translate(targets, path))
					path.pop()
				else if typeof targets == typeof ""
					console.log("Pushing path: ", targets)
					path.push targets
	appFiles

appFiles = translate(appFiles)
console.log(appFiles)

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
	test_path     = "src/01_tinycpu/tests/features"
	p = spawn "node", [test_path],
		env:
			NODE_PATH: node_path
		stdio: [0, 1, 2]
	console.log("Node starting up")
	p.on 'exit', (code) ->
		console.log("Node quit, finishing")
		process.exit(code)
