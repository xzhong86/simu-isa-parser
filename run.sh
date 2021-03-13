#!/bin/sh

#racc=/usr/local/Cellar/ruby/2.7.1_2/bin/racc
racc=racc

mkdir -p gen
$racc isa-def.racc -v -o gen/isa-def.racc.rb
ruby test.rb
