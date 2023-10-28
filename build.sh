#!/bin/bash

set -e

# First param of script must be path to zig std lib
# like so:
#
#   build.sh /home/dave/zig/lib/std/
#
# Second param CAN be wildcard match:
#
#   $ ./build.sh /home/dave/zig/lib/std/ queue
#   atomic/queue.zig
#   priority_queue.zig
#   priority_dequeue.zig
#
# This script ALWAYS writes to a dir called "output/"
# in the current working directory!
#
lib_dir=$1
matchy=$2

# copy stylesheet first
cp styles.css output/

for file in $(find $lib_dir -name '*.zig')
do
    # Only output files matching argument 2
    [[ $matchy && $file != *$matchy* ]] && continue

    # Skip zig-cache!
    [[ $file == *zig-cache* ]] && continue

    relative_file=${file#"$lib_dir"}
    output_file="output/$relative_file.html"

    echo $relative_file
    mkdir -p $(dirname $output_file)
    ruby makepage.rb $file $relative_file > $output_file
done
