Game I'm working on... That's it.

If the game suddenly crashes, take the content from output.log and open an [issue](https://github.com/ChipCruncher72/TheGameOrSmth/issues/new).\
Make sure to be descriptive and explain what you did when the game crashed.

If you want to download and try it out, first download [Zig](https://ziglang.org/download/) and add it to your path

Then run `zig build run` in the same directory as the `build.zig` file to run it\
you should also be able to find the executable in `zig-out/bin` afterwards

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
