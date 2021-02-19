
require_relative 'ISAParser'

# main
parser = ISAParser.new
parser.scan_file('../op-class.def')
parser.scan_file('../op-01-rv32i.def')

parser.insts.each{ |i| parser.print_inst(i) }
