#!/usr/bin/bash

./build.sh /home/dave/zig/lib/std
cd output
rsync -a .* ratf:www/zig/stdlib-browseable2/
