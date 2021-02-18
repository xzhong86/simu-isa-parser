
require_relative 'isa-def-rex'
require_relative 'gen/isa-def.racc'

class ISADefParser < Racc::Parser

  def parse(str)
    scan_setup(str)
    do_parse
  end

  def load_file( filename )
    @filename = filename
    File.open(filename, "r") do |f|
      scan_setup(f.read)
    end
  end

  def scan_file( filename )
    load_file(filename)
    do_parse
  end

end
