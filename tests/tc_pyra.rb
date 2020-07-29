# File:  tc_simple_number.rb

require_relative "../pyra"
require "test/unit"
require 'stringio'

# https://stackoverflow.com/a/22777806/2531987
def with_captured_stdout
  original_stdout = $stdout  # capture previous value of $stdout
  $stdout = StringIO.new     # assign a string buffer to $stdout
  yield                      # perform the body of the user code
  $stdout.string             # return the contents of the string buffer
ensure
  $stdout = original_stdout  # restore $stdout to its previous value
end

def with_defined_stdin(stdin)
  original_stdin = $stdin
  $stdin = StringIO.new(stdin)
  yield
ensure
  $stdin = original_stdin
end

def random_string
  ('a'..'z').to_a.shuffle[0,8].join
end

def assert_message(message)
  begin
    yield
  rescue => e
    assert_equal(e.message,message)
  end
end

class TestPyra < Test::Unit::TestCase
 
  def test_indices
    assert_equal(indices('zxcbvbnm','b'),[3,5])
  end
 
  def test_unwrap
    assert_equal(unwrap(['hello']),'hello')
    x = [1,2,'hello']
    assert_equal(unwrap(x),x)
  end

end

class TestTriangleParser < Test::Unit::TestCase

  def test_empty
    assert_message("no triangle found") {
      triangle_from(''.lines)
    }
  end

  def test_trinagle_end_1
    assert_message("unexpected triangle end") {
      triangle_from(" ^ \n/ \\".lines)
    }
  end

  def test_trinagle_end_2
    assert_message("unexpected triangle end") {
      triangle_from(" ^ \n/ \\\n--".lines)
    }
  end

  def test_right_side_too_shot
    assert_message("right side too short") {
      triangle_from(" ^ \n/  ".lines)
    }
  end

  def test_left_side_too_shot
    assert_message("left side too short") {
      triangle_from(" ^ \n  \\".lines)
    }
  end

  def test_malformed_bottom
    assert_message("malformed bottom") {
      triangle_from(" ^ \n/ \\\n-- ".lines)
    }
  end

  def test_large_triange
    c = triangle_from("   ^ \n  / \\\n /   \\\n/hello\\\n-------".lines)
    assert_equal(c,["hello"])
  end

  def test_tiny_triangle
    c = triangle_from("^\n-".lines)
    assert_equal(c,[""])
  end

end

class TestStringToVal < Test::Unit::TestCase

  def test_line
    coms = ["line","stdin","readline"]
    coms.each { |com|
      v = random_string
      with_defined_stdin(v) {
        assert_equal(str_to_val(com),v)
      }
    }
  end

end

class TestPrograms < Test::Unit::TestCase
 
  def test_greeting
    out = with_captured_stdout {
      args = [__dir__ + '/hi.pyra']
      run_pyra(args)
    }
    assert_equal('hi!',out,"Greeting program failed")
  end
 
end