# File:  tc_simple_number.rb

require_relative "../pyra"

t = "   ^ \n  / \\\n /   \\\n/hello\\\n-------"
puts t
p triangle_from(t.lines)