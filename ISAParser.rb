
require_relative 'ISADefParser'

class ISAParser

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
    def decode_code()      @c_codes['DECODE'] end
    def execute_code()     @c_codes['EXECUTE'] end
    def disasm_code()      @c_codes['DISASM'] end
  end

  # ========= ISA Hooker =========
  class ISAHooker
    attr_reader :insts
    def initialize()
      @insts = []
      @insts_map = {}
      @curr_c_code = ""
    end
    def start_isa_block(args)
      type, name, bin_str = args
      inst = @insts_map[name]
      if not inst
        inst = ISAInstInfo.new type, name, bin_str
        @insts_map[name] = inst
      else
        fail if bin_str
      end
      @curr_inst = inst
    end
    def end_isa_block(args)
      inst = @curr_inst
      @insts << inst
      @curr_inst = nil
    end
    def start_c_block(args)
      type = args[0]
      @curr_type = type
      @curr_c_code = ""
    end
    def end_c_block(args)
      code = args[0]
      #@curr_inst.set_c_code(@curr_type, code)          # parsed c code (blank removed)
      @curr_inst.set_c_code(@curr_type, @curr_c_code)  # origin c code
      @curr_type = nil
    end

    def call_func(args)
      #func_name = args[0]
      #puts "in inst #{@curr_inst.name} #{@curr_type} call to #{func_name}"
    end

    def any_token(args)
      text, token = args
      @curr_c_code += text
    end
  end


  # ========= class ISAParser =========

  def initialize
    @hook = ISAHooker.new
    @parser = ISADefParser.new

    @parser.set_isa_hook() do |action, args|
      if @hook.methods.include? action
        @hook.method(action).call(args)
      end
    end
  end

  def scan_file(file)
    @parser.scan_file(file)
  end

  def insts()
    @hook.insts
  end
  def print_inst(inst)
    puts "#{inst.type} #{inst.name} #{inst.bin_str}"
    puts "  DECODE: '#{inst.decode_code}'" if inst.decode_code
    puts "  EXECUTE: '#{inst.execute_code}'" if inst.execute_code
    puts "  DISASM: '#{inst.disasm_code}'" if inst.disasm_code
    puts ""
  end
end

