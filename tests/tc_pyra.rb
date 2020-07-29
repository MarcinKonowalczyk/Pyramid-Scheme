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


class TestPyra < Test::Unit::TestCase
 
  def test_simple
    out = with_captured_stdout {
    args = [__dir__ + '/hi.pyra']
    run_pyra(args)
    }
    assert_equal('hi!',out,"Greeting program failed")
  end
 
end