#!/bin/bash

perl compile.pl
dest_dir="$HOME/apps/wml/xhtml/1.x/std/"
mkdir -p "$dest_dir"
cp std/toc/toc.wml "$dest_dir"
