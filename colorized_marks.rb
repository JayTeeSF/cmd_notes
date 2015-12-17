# red-x: "\e[0;31;49m✕\e[0m"
# green-check: "\e[0;32;49m✓\e[0m"

require 'colorize'
puts "✓".colorize(:green)
puts "✕".colorize(:red)

