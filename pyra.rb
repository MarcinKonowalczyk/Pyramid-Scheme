#!/usr/bin/ruby

def indices(str, chr)
    (0 ... str.length).find_all { |i| str[i] == chr }
end

def unwrap(t)
    t.size == 1 ? t[0] : t
end

$TOP    = "^"
$BOTTOM = "-"
$L_SIDE = "/"
$R_SIDE = "\\"

def triangle_from(lines, ptr_inds = nil)
    raise "no triangle found" if !lines.first
    ptr_inds = ptr_inds || indices(lines.first, $TOP)
    row = ""
    ptr_inds.map { |pt|
        x1 = x2 = pt # left and right sides
        y = 0
        data = []
        loop {
            x1 -= 1; x2 += 1; y += 1 # Go to the next row, left and right 
            row = lines[y]
            raise "unexpected triangle end" if !row or x2 > row.size
            
            # Check for mismatched sides
            r_side = row[x2] == $R_SIDE
            l_side = row[x1] == $L_SIDE
            raise "right side too short" if l_side and not r_side
            raise "left side too short" if r_side and not l_side
            
            # Are we done?
            if not l_side and not r_side
                correct_bottom = (x1 + 1 .. x2 - 1).all? { |x| row[x] == $BOTTOM }
                raise "malformed bottom" if not correct_bottom
                break
            end

            # We aren't done
            data.push row[x1 + 1 .. x2 - 1]
        }
        op = data.join("").gsub(/\s+/, "")
        args = []
        if row[x1] == $TOP or row[x2] == $TOP
            next_inds = [x1, x2].find_all { |x| row[x] == $TOP }
            args.push triangle_from(lines[y..-1], next_inds)
        end
        unwrap [op, *args]
    }
end

$vars = {"eps" => ""}
$UNDEF = :UNDEF

def parse(str)
    # find ^s on first line
    lns = str.lines
    triangle_from(lns)
end

# converts a string to a pyramid value
def str_to_val(str)
    # todo: expand
    if $vars.has_key? str
        $vars[str]
    elsif str == "line" or str == "stdin" or str == "readline"
        $stdin.gets
    else
        str.to_f
    end
end

def val_to_str(val)
    sanitize(val).to_s
end

def falsey(val)
    [0, [], "", $UNDEF, "\x00", nil].include? val
end

def truthy(val)
    !falsey val
end

class TrueClass;  def to_i; 1; end; end
class FalseClass; def to_i; 0; end; end

$outted = false

$uneval_ops = {
    "set" => -> (left, right) {
        $vars[left] = eval_chain right
        $UNDEF
    },
    # condition: left
    # body: right
    "do" => -> (left, right) {
        loop {
            eval_chain right
            break unless truthy eval_chain left
        }
        $UNDEF
    },
    # condition: left
    # body: right
    "loop" => -> (left, right) {
        loop {
            break unless truthy eval_chain left
            eval_chain right
        }
        $UNDEF
    },
    # condition: left
    # body: right
    "?" => -> (left, right) {
        truthy(eval_chain left) ? eval_chain(right) : 0
    }
}

$ops = {
    "+" => -> (a, b) { a + b },
    "*" => -> (a, b) { a * b },
    "-" => -> (a, b) { a - b },
    "/" => -> (a, b) { 1.0 * a / b },
    "^" => -> (a, b) { a ** b },
    "=" => -> (a, b) { (a == b).to_i },
    "<=>" => -> (a, b) { a <=> b },
    "out" => -> (*a) { $outted = true; a.each { |e| print e }; },
    "chr" => -> (a) { a.to_i.chr },
    "arg" => -> (*a) { a.size == 1 ? ARGV[a[0]] : a[0][a[1]] },
    "#" => -> (a) { str_to_val a },
    "\"" => -> (a) { val_to_str a },
    "" => -> (*a) { unwrap a },
    "!" => -> (a) { falsey(a).to_i },
    "[" => -> (a, b) { a },
    "]" => -> (a, b) { b },
    "nil" => -> (*a) { unwrap a; nil },
}

def eval_chain(chain)
    op, args = chain
    args = [] if args == nil # Set args to [] if chain was just a string
    # Match against all possible operations
    if $uneval_ops.has_key? op
        return $uneval_ops[op][*args] rescue ArgumentError
    end
    if $ops.has_key? op
        return sanitize $ops[op][*sanitize(args.map { |ch| eval_chain ch })] rescue ArgumentError
    end
    # It is maybe a string?
    if args.empty? then return str_to_val op end
    raise "undefined operation `#{op}`" # Finally blow up if not matched against anything
end

def sanitize(arg)
    if arg.is_a? Array
        arg.map { |e| sanitize e }
    elsif arg.is_a? Float
        arg == arg.to_i ? arg.to_i : arg
    else
        arg
    end
end

def run_pyra(arg)
    prog = File.read(arg[0]).gsub(/\r/, "")
    parsed = parse(prog)
    res = parsed.map { |ch| eval_chain ch }
    res = res.reject { |e| e == $UNDEF } if res.is_a? Array
    res = res.is_a?(Array) && res.length == 1 ? res.pop : res
    to_print = sanitize(res)
    unless $outted
        if arg[1] && arg[1][1] == "d"
            p to_print
        else
            puts to_print
        end
    end
end

if __FILE__ == $0
    run_pyra(ARGV)
end

# p $vars
