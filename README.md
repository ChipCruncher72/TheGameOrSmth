Game I'm working on... That's it.

IF YOU ENCOUNTER ANY ERRORS OR CRASHES COPY THE CONTENT OF THE OUTPUT.LOG FILE AND PASTE IT IN AN [ISSUE](https://github.com/ChipCruncher72/TheGameOrSmth/issues)

If you want to download and try it out, first download [Zig](https://ziglang.org/download/) and add it to your path

Then run `zig build run` in the same directory as the `build.zig` file to run it\
you should also be able to find the executable in `zig-out/bin` afterwards, make sure it's moved to the same directory as assets or else it'll crash

### Controls:
- WASD/Arrow keys - move player
- Esc - Quit
- U - enable unlimited fps press U again to set it back to 60
- F1 - shows debug information (i.e. FPS, player position, player rotation, camera zoom, host name)\
   Press F1 again to disable it
- +/- keys - change camera zoom
- </> keys - rotate player
- R - reset rotation to zero
- F11 - toggle fullscreen
