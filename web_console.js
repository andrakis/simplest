var web_console;
(function() {
	var methods = {
		flat: DumpObjectFlat,
		indented: DumpObjectIndented
	};
	var dumpMethod = methods['indented'];
	// Causes console.log to write to an element
	console.log = (function (old_function, div_log) {
		return function () {
			var text = [], i = 0, arg;
			for ( ; i < arguments.length; i++ ) {
				arg = arguments[i];
				if (typeof arg == typeof {})
					text.push(dumpMethod(arg));
				else if (typeof arg == 'undefined')
					text.push('undefined');
				else
					text.push(arg.toString());
			}
			text = text.join(' ');
			div_log.innerHTML += text + "\n";
			div_log.scrollTop = div_log.scrollHeight;
		};
	}(console.log.bind(console), document.getElementById("log")));
})();
web_console = console;
