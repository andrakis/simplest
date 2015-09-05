Simplest
========

Simplest is a collection of projects that aims for simplicity of
implementation, thereby allowing ease of porting.

The projects currently under development are:

* TinyCPU
	TinyCPU is a One Instruction Set Computer (OISC), which is designed to be modular and
	easy to port. Features extend the capabilities of the CPU to provide modern
	conveniences such as interrupts, DMA, paging, and virtual hardware.

	A usually up to date example page is up at http://www.thedaedalus.net/simplest

	TinyCPU is currently in an early operational state, with several features implemented and some sample programs.

	It is an iteration over some previous projects:

	* [Cumulative](https://github.com/andrakis/gleam/blob/master/cumulative/cumulative.html) initial working implementation of the OISC design.
	* [Gleam](https://github.com/andrakis/gleam) a C port of Cumulative, which replaced the simple memory hash with paging.

	Portability is a prime concern, and the CPU can be compiled into a number of
	formats:

	* app - everything is compiled into app.js, and a set of wrappers are used to provide proper module importing. This can be used as a standalone application by node.js, or used on a webpage.
	* node - each coffeescript file is compiled into a .js file for use with node.js

	Features are presently implemented in Coffeescript. They provide a base interface for anyone who wishes to port to another platform.

* Concur
	Concur is an object-based virtual machine that aims for concurrency and communications between concur processes.

	Its design is heavily influenced by Erlang.

	Concur is currently in a very early state.

