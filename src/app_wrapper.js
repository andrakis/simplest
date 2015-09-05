// App wrapper start
var modules = {}, ref;

var start_time = +new Date();

orig_require = require;
var obtain = function(path) {
	if (__verbose__) console.log("obtain(" + path + ")");
	for(key in modules)
		if (__verbose__) console.log("  have: '" + key + "'");
	if (__verbose__) console.log("Match is ", modules[path], path in modules);
	if( modules[path] ) {
		if (__verbose__) console.log("found, returning: ", modules[path]);
		return modules[path];
	} else {
		if (__verbose__) console.log("not found, using require");
		return orig_require(path);
	}
};

require = obtain;

if (typeof web_console != 'undefined') {
	console = web_console;
}
