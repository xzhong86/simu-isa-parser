
require 'racc/parser'

#require_relative 'gen/clang.racc'

class ISADefParser < Racc::Parser
  require 'strscan'

  attr_reader   :lineno
  attr_reader   :filename
  attr_reader   :curr_line
  attr_accessor :state

  def setup_isa_regexp
    @isa_top_keyword    = %w[ INST_CLASS INST ]
    @isa_block_keyword  = %w[ CLASS DECODE EXECUTE DISASM ]
    @isa_state = :top # :isa_arg :isa_block, :c_block
    regexp = Regexp.new '(' + (@isa_top_keyword + @isa_block_keyword).join('|') + ')\b'
    action = proc do |text|
      if @isa_top_keyword.include? text
        @isa_state = :isa_arg
        [text.to_sym, text]
      else
        if @isa_state == :isa_block
          [ text.to_sym, text ]
        else
          [ :id, text ]
        end
      end
    end
    @isa_regexp_action  = Struct.new(:regexp, :action).new(regexp, action)
  end
  def isa_hook(action, args)
    case action
    when :start_isa_block
      @isa_state = :isa_block

    when :end_isa_block
      @isa_state = :top

    when :start_c_block
      @isa_state = :c_block

    when :end_c_block
      @isa_state = :isa_block

    else
      ;
    end
    @isa_hook.call(action, args) if @isa_hook
  end
  def set_isa_hook(proc = nil, &blk)
    @isa_hook = proc || blk
  end

  def setup_c_regexp
    c_keywords = %w[enum struct union if else switch case for do while continue break return sizeof ]
    c_std_types = %w[void char short int long float double signed unsigned ]
    c_ext_types = %w[int8 int16 int32 int64 uint8 uint16 uint32 uint64 ]
    op_3char = %w[ >>= <<= ]
    op_2char = %w[ || && == != <= >= ++ -- -> *= /= %= += -= &= |= ^= >> << ]
    op_1char = %w[ + - * / % > < | & ^ ! ~ = ]

    @regexp_c_keywords = Regexp.new('(' + c_keywords.join('|') + ')\b')
    @regexp_c_types    = Regexp.new('(' + (c_std_types + c_ext_types).join('|') + ')\b')
    c_ops = (op_3char + op_2char + op_1char).map{ |op| op.gsub(/([*+|?^$])/, 'XX\1').gsub('XX', '\\') }
    @regexp_c_ops = Regexp.new(c_ops.join('|'))
    @c_op_types = Hash.new(:op_bin)
    @c_op_types.merge! %w[ >>= <<= *= /= %= += -= &= |= ^= = ].map{ |op| [ op, :op_assg ] }.to_h
    @c_op_types.merge! %w[ ++ -- ].map{ |op| [ op, :op_incr ] }.to_h
    @c_op_types.merge! %w[ * & - ].map{ |op| [ op, :op_2_1 ] }.to_h
  end

  def scan_setup(str)
    setup_c_regexp() if not @regexp_c_keywords
    setup_isa_regexp if not @isa_regexp_action
    @ss = StringScanner.new(str)
    @lineno =  1
    @curr_line = ""
    @state  = nil
  end

  def hook_token(text, token)
    type = token[0]
    if type != :newline
      @curr_line += text
    else
      @curr_line = ""
    end
    isa_hook(:any_token, [ text, token ])
    if type == :comment or type == :blank or type == :newline
      token = nil
    end
    token
  end

  def _next_token
    text = @ss.peek(1)
    @lineno  +=  1  if text == "\n"
    if @state != nil
      raise  ScanError, "undefined state: '" + state.to_s + "'"
    end
    token = 
      case
      when text = @ss.scan(@isa_regexp_action.regexp)
        @isa_regexp_action.action.call(text)

      # example 0101<2.op2><5.rs>11001<3.func>11100
      when @isa_state == :isa_arg && text = @ss.scan(/([01]+|<\d+\.\w+>)+/)
        [ :bin_str, text ]

      when text = @ss.scan(@regexp_c_keywords)  then [ text.upcase.to_sym, text ]

      when text = @ss.scan(@regexp_c_types)     then [ :type_const, text]

      when text = @ss.scan(/\/\/[^\n]*/)        then [ :comment, text ]
      when text = @ss.scan(/\/\*.*\*\//)        then [ :comment, text ]
      when text = @ss.scan(/\n/)                then [ :newline, text ]
      when text = @ss.scan(/\s+/)               then [ :blank, text ]

      when text = @ss.scan(@regexp_c_ops)       then [ @c_op_types[text], text ]

      when text = @ss.scan(/[;,?:(){}\[\]]/)    then [ text, text ]

      when text = @ss.scan(/0[xX]\h+|0[bB][01]+|\d+/)   then [ :literal_int, text ]
      when text = @ss.scan(/\d+\.\d+/)                  then [ :literal_float, text ]
      when text = @ss.scan(/'.'/)                       then [ :literal_char, text ]
      when text = @ss.scan(/"(\\\"|[^"])*"/)            then [ :literal_string, text ]
      when text = @ss.scan(/[_a-zA-Z]\w*/)              then [ :id, text ]

      else
        text = @ss.string[@ss.pos .. -1]
        raise  ScanError, "can not match: '" + text + "'"
      end
    [ token, text ]
  end  # def _next_token
  def next_token
    while not @ss.eos?
      token, text = _next_token
      token = hook_token(text, token)
      return token if token
    end
    nil
  end

end


