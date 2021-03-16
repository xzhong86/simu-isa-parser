
require_relative 'ISAParser'

# main
riscv_isa_def = '../../arch/riscv/isa-def/'
parser = ISAParser.new
parser.scan_file(riscv_isa_def + 'op-class.def')
parser.scan_file(riscv_isa_def + 'op-01-rv32i.def')

parser.insts.each{ |i| parser.print_inst(i) }
