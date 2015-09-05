01 - TinyCPU
============

TinyCPU is a OISC (One Instruction Set Computer) designed for modularity and
flexibility.

Directories
-----------

The directory structure is as follows:
	a_assembler        TinyCPU Assembler (TCA)
	a_lib              Assembly library files and sources
	a_src              Assembly source files
	features           Loadable CPU features
	  -- interrupts    Features for working with interrupts
	  -- io            Input/output features
	  -- mm            Memory management features
	  -- watchers      CPU watchers
	tests              Tests of the TinyCPU system

Assembly
--------

There are to be a number of assembler sources. These are to be compiled with
tca - the TinyCPU assembler.

Running
-------

Running the CPU tests is easy. Run "cake" to view the targets. The targets
in detail are:
	run                Run the CPU in standard (non-verbose) mode
	run_verbose        Run with maximum verbosity
	test_paging        Test the paging memory management feature
	test_asm           Test the assembler