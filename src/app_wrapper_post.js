// App wrapper post

var init_complete_time = +new Date();
var diff = init_complete_time - start_time;
if (__verbose__) console.log("\nApplication init complete, modules registered in ", diff, "ms");

// invoke the app
require('tests/features').test();
