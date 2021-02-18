
require 'racc/parser'

#require_relative 'gen/clang.racc'

class ISADefParser < Racc::Parser
  require 'strscan'

  attr_reader   :lineno
  attr_reader   :filename
  attr_accessor :state

  def setup_c_regexp
    c_keywords = %w[enum struct union if else switch case for do while continue break return sizeof ]
    c_std_types = %w[void char short int long float double signed unsigned ]
    c_ext_types = %w[int8 int16 int32 int64 uint8 uint16 uint32 uint64 ]
    op_3char = %w[ >>= <<= ]
    op_2char = %w[ || && == != <= >= ++ -- -> *= /= %= += -= &= |= ^= >> << ]
    op_1char = %w[ + - * / % > < | & ^ ! ~ = ]

    @regexp_c_keywords = Regexp.new(c_keywords.join('|'))
    @regexp_c_types = Regexp.new((c_std_types + c_ext_types).join('|'))
    c_ops = (op_3char + op_2char + op_1char).map{ |op| op.gsub(/([*+|?^$])/, 'XX\1').gsub('XX', '\\') }
    @regexp_c_ops = Regexp.new(c_ops.join('|'))
    @c_op_types = Hash.new(:op_bin)
    @c_op_types.merge! %w[ >>= <<= *= /= %= += -= &= |= ^= = ].map{ |op| [ op, :op_assg ] }.to_h
    @c_op_types.merge! %w[ ++ -- ].map{ |op| [ op, :op_incr ] }.to_h
  end

  def scan_setup(str)
    setup_c_regexp() if not @regexp_c_keywords
    @ss = StringScanner.new(str)
    @lineno =  1
    @state  = nil
  end
  def _next_token
    text = @ss.peek(1)
    @lineno  +=  1  if text == "\n"
    if @state != nil
      raise  ScanError, "undefined state: '" + state.to_s + "'"
    end
    token = 
      case
      when text = @ss.scan(@regexp_c_keywords)
        [ text.upcase.to_sym, text ]

      when text = @ss.scan(@regexp_c_types)
        [ :type_const, text]

      when text = @ss.scan(@regexp_c_ops)
        [ @c_op_types[text], text ]

      when text = @ss.scan(/[;,?:(){}\[\]]/)
        [ text, text ]

      when text = @ss.scan(/\d+|0[xX]\h+|0[bB][01]+/)
        [ :literal_int, text ]
      when text = @ss.scan(/\d+\.\d+/)
        [ :literal_float, text ]
      when text = @ss.scan(/'.'/)
        [ :literal_char, text ]
      when text = @ss.scan(/"(\\\"|[^"])*"/)
        [ :literal_string, text ]
      when text = @ss.scan(/[_a-zA-Z]\w*/)
        [ :id, text ]

      when text = @ss.scan(/\/\/.*\n?/)
        nil #[ :comment, text ]
      when text = @ss.scan(/\/\*.*\*\//)
        nil #[ :comment, text ]
      when text = @ss.scan(/\s+/)
        nil #[ :blank, text ]

      else
        text = @ss.string[@ss.pos .. -1]
        raise  ScanError, "can not match: '" + text + "'"
      end
    token
  end  # def _next_token
  def next_token
    return if @ss.eos?
    # skips empty actions
    until token = _next_token or @ss.eos?; end
    token
  end

end


