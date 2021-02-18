
require_relative 'ISADefParser'

# main
def do_test(str)
  p = $parser
  begin
    res = p.parse str
    puts "test: `#{str}' => `#{res}'"
  rescue
    puts "parsing: `#{str}'"
    raise
  end
end

$parser = ISADefParser.new
#p $parser.methods

do_test "a=1;"
do_test "a = 1;"
do_test "a = 1 + 3;"
do_test "a = 1 * 3;"
do_test "a = b ? 2 * c : b * 3;"
do_test "if(a == b) c += 1;"
do_test "if(a == b) { c += 1; }"
do_test "if(1) { c += 1; a != 1; b = 2;}"
do_test "for(i=0;i<10;i+=1);"
#do_test "for(i=0; i<10; ) i+=1;"
do_test "if (a) a+= 1; else b+=1;"
do_test "{{ if (a) a+= 1; else b+=1; }}"
do_test "while(x<100) x++;"
do_test "do ++x; while(x<100);"
do_test "{\n if (test(a+b)) {\n  printf(\"a=%d,b=%d\",\n a,b);\n }\n}\n"
