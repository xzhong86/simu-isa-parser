
require_relative 'ISADefParser'

class Integer
  def fmt_str(fmt)
    sprintf(fmt, self)
  end
end

class ISAParser

  FieldInfo = Struct.new :hi, :lo, :name, :value
  class FieldInfo
    def width()      hi - lo + 1 end
    def bin_str(with_name: nil)
      if value
        sprintf "%0*b", width, value
      elsif name and with_name
        "<#{width}.#{name}>"
      else
        'x' * width
      end
    end
  end

  class BitFields
    attr_reader :string, :width, :fields
    def initialize(str)
      @width = 0
      @fields = []
      @string = str
      init_with_string(str)
    end
    def init_with_string(str)
      ss = StringScanner.new(str)
      hi = 31
      while text = ss.scan(/[01]+|<\d+\.[\w]+>/)
        field, w = nil, 0
        if text =~ /^[01]+/
          w = text.length
          field = FieldInfo.new hi, hi - w + 1, nil, text.to_i(2)
        elsif text =~ /^<(\d+)\.([\w]+)>/
          w, name = $1.to_i, $2
          field = FieldInfo.new hi, hi - w + 1, name, nil
        else
          fail
        end
        hi = hi - w
        @width += w
        @fields << field
      end
      fail "bad binary string" if not ss.eos?
    end

    def get_bit_str(map = nil) # 0101xxxx01x
      str = fields.map{ |f| f.bin_str }.join('')
      map ? str.each_char.map{ |c| map[c] || c }.join('') : str
    end
  end

  class ISAInstInfo
    attr_reader :type, :name, :bin_str
    attr_reader :c_codes, :bitfield
    def initialize(t, n, s)
      @type, @name, @bin_str = t, n, s
      @bitfield = BitFields.new(s)
      fail if bitfield.width != 32
      @c_codes = {}
    end

    def bit_str(m=nil)  @bitfield.get_bit_str(m) end
    def mask_val()      bit_str({ '0' => '1', 'x' => '0' }).to_i(2) end
    def match_val()     bit_str({ '0' => '0', 'x' => '0' }).to_i(2) end

    def c_name()        @name.gsub(/[-.]/, '_') end
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
    bit_str = inst.bit_str
    msk_str = inst.mask_val.fmt_str "%08x"
    val_str = inst.match_val.fmt_str "%08x"
    name = "%-8s" % [ inst.name ]
    puts "#{inst.type} #{name} #{msk_str} #{val_str} #{inst.bin_str}"
    #puts "  DECODE: '#{inst.decode_code}'" if inst.decode_code
    #puts "  EXECUTE: '#{inst.execute_code}'" if inst.execute_code
    #puts "  DISASM: '#{inst.disasm_code}'" if inst.disasm_code
    #puts ""
  end
end

