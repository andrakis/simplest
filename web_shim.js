// Ensures code written for node.js works in the browser

function stub (name) {
	return function() {
		console.log("STUB: for " + name + " called with ", arguments);
		return undefined;
	};
}

if (typeof require == 'undefined') require = stub('require');
if (typeof process == 'undefined') {
	process = {
		env: {
			TINY_VERB: 0
		},
		platform: 'browser',
		nextTick: function (callback) {
			setTimeout(callback, 0);
		}
	};
}

