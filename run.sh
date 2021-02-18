#!/bin/sh

mkdir -p gen
racc isa-def.racc -v -o gen/isa-def.racc.rb
ruby test.rb
