# Browseable Zig standard library 2

This is a little Ruby program that creates a browseable HTML mini-site from
the Zig standard library source.


The style was inspired by (as in, nearly identical to)
<a href="https://web.archive.org/web/20120428101624/http://jashkenas.github.com/docco/">docco.coffee</a> (archive.org).

To make it browseable, `@import()` calls get converted to hyperlinks.

<a href="http://ratfactor.com/zig/stdlib-browseable2/std.zig.html">See it live here!</a>

![screenshot of example output](http://ratfactor.com/zig/stdlib-browseable/screenshot.png)


## Run it!

The Ruby program generates a page for one Zig file at a time.

There's a Bash script to make the whole site.

The first parameter of the script must be a path to a Zig Std Lib (ending in trailing slash `/`):

    ./build.sh /home/dave/zig/lib/std/

The second parameter _can_ be a wildcard match of files/directories to generate:

    ./build.sh /home/dave/zig/lib/std/ queue
    atomic/queue.zig
    priority_queue.zig
    priority_dequeue.zig

    dwarf.zig
    target.zig
    crypto/blake2.zig
    crypto/aes_ocb.zig
    ...

Output will be generated in a new directory named `output/` in the current
working directory.

TODO: I don't need Bash here. Ruby can do all of this. I just used it because
I'd already written it for the previous version of this program.
