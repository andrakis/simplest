// Wrap_post.js, for __file__
	return exports;
});

if( modules ) {
	if (__verbose__) console.log("Registering __file__");
	var namespace = {test:1};
	var ex = {ex: 1};
	var module = {mod: 1};
	var ex_obtain = function(path) {
		if (__verbose__) console.log("obtain from __file__");
		return obtain(path);
	};
	res = ref.call(namespace, ex_obtain, ex, module);
	if (__verbose__) console.log("Res is", res);
	modules['__file__'] = module.exports;
	if (__verbose__) console.log("Namespace is", namespace);
	if (__verbose__) console.log("Exports is", ex);
	if (__verbose__) console.log("Registered __file__ as", modules['__file__']);
} else {
	if (__verbose__) console.log("Standard export");
	ref(require, exports);
}
