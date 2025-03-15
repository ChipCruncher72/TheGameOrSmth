#include <stdio.h>

// Zig does not like the `stdout` macro, so this is a work around
FILE* get_stdout() {
    return stdout;
}

// Ditto
FILE* get_stderr() {
    return stderr;
}
