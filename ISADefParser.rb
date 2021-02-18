
require_relative 'isa-def-rex'
require_relative 'gen/isa-def.racc'

class ISADefParser < Racc::Parser

  def parse(str)
    scan_setup(str)
    begin
      do_parse
    ensure
      puts "parsing failed at #{filename}:#{lineno}"
      raise
    end
  end

  def load_file( filename )
    @filename = filename
    File.open(filename, "r") do |f|
      scan_setup(f.read)
    end
  end

  def scan_file( filename )
    @filename = filename
    File.open(filename, "r") do |f|
      parse(f.read)
    end
  end

end
