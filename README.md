# Hello
## Quick tour:
- Engine folder:  
    Has Core functionality of a game engine
- Plugins folder:  
    Dependencies and custom code lives here
  
- build.zig:  
    Main build file which manages build logic etc.
- build.zig.zon:  
    ZON - Zig Object Notation. Used by zig's custom package manager, here used to allow users to easily download and manage engine with zig
- config.zig:  
    Main configuration file, manages build versions, conditions, output directories (for now a bit useless)
- dependencies.zig:  
    Dependency managing file, allows user to download specific builds of packages, change build conditions(for now does nothing)
- .dependencies:  
    File that notates what dependencies are planned to use, has no functionality, only for notating.

- Test folder:  
    This is where singular game engine is compiled to. Not ready for distribute but easy to test
- Distribute folder:  
    Folder of archives of different game engine builds, ready for distribution

# Forking
If you would like to bring this project to other build system, language, have other bindings you are free to do so. 
As long as it doesn't violate MIT license and isn't made for malicious purposes or can potentially cause dammage to users, me, project, or other contributors.