
require_relative 'ISADefParser'

# main

class ISAInstInfo
  attr_reader :type, :name, :bin_str
  attr_reader :c_codes
  def initialize(t, n, s)
    @type, @name, @bin_str = t, n, s
    @c_codes = {}
  end
  def set_c_code(type, code)
    if @c_codes[type]
      fail
    end
    @c_codes[type] = code
  end
  def decode_code()      @c_codes[:DECODE] end
  def execute_code()     @c_codes[:EXECUTE] end
  def disasm_code()      @c_codes[:DISASM] end
end

class ISAHooker
  def initialize
    @insts = {}
  end
  def start_isa_block(args)
    type, name, bin_str = *args
    inst = @insts[name]
    if not inst
      inst = ISAInstInfo.new type, name, bin_str
      @insts[name] = inst
    else
      fail if bin_str
    end
    @curr_inst = inst
  end
  def end_isa_block(args)
    inst = @curr_inst
    puts "Inst #{inst.name}(#{inst.type}) is defined."
    @curr_inst = nil
  end
  def start_c_block(args)
    type = args[0]
    @curr_type = type
  end
  def end_c_block(args)
    code = args[0]
    @curr_inst.set_c_code(@curr_type, code)
    @curr_type = nil
  end
end
$hook = ISAHooker.new

$parser = ISADefParser.new

$parser.set_isa_hook() do |action, args|
  if $hook.methods.include? action
    $hook.method(action).call(args)
  end
end

$parser.scan_file('../op-01-rv32i.def')
