# Something very important
std.Build.StandartOptimizeOptions(.{});
Doesn't pass optimize correctly to the dependencies!
Use b.option(bool, "optimize", ...) or set it manually.  

# Table of context
- [What this repository is](#what-this-repository-is)
- [Example on how to use it](#example-on-how-to-use-it)
- [Features](#for-now-this-engine-can)
- [Dependencies](#dependencies)
- [Requirements](#requirements)

## What this repository is
**For now only singlethreading mode is capable of managing windows with GLFW without bugs**
It is a repository for a game engine, it is made for saving my work and maybe a community work.
I'm making it as a hobby.

## Example on how to use it
I've made an example "game" on this repository: [link](https://github.com/Freziyt223/Heat-game)

## For now this engine can:
- Print to console,
- Print colourful text to console(if terminal supports colour),
- Has proper init, update and deinit functions,
- Multithreading queue,(only without window management with GLFW)
- Stage multiple update function with specific tick-rates(uses queue),

Windowing and terminal user interface is still not ready, so don't use it.
I'd be very pleased if anyone would help me with setting up glfw windowing or TUI.

## Dependencies
**ztracy-master(not required)** - This is a profiling tool so you can track perfomance of the engine  
**zigzag-master(required)** - This is a very powerful Terminal User Interface(TUI)  
**zglfw-master(required)** - This is a binding for a GLFW, which is a library for working with  windows(window and not microsoft windows)

# Requirements
**Remark**
Make sure to clean up .zig-cache time to time because it can grow a lot in space.
Enabling strip doesn't generate pdb file so it may save you some space.
- Zig version 0.15.X
- 27.4 kb for source code
- As for disk space, i didn't test it. I've only tested it with game so check how much example game took. Here is [link](https://github.com/Freziyt223/Heat-game).

# What you can do with it?
First of all, here i've made something i've never seen in zig projects, which is making an separate config.zig file to manage the project and also adding ability to edit it from anywhere.
Use it as a starter, add platform specific IO for example, so it may run faster than std.
This repo uses zigs IO, making custom allocators(check src/TrackingAllocator.zig), multithreading and type passing in runtime, which can be useful in some projects.x