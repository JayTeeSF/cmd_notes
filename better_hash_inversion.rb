#!/usr/bin/env ruby
define_hash  = 'h = {:a => 1, :b => 1, :c => 2}'
invert_hash  = 'h.invert'
puts 'the default Hash#invert method ignores keys with non-unique values.'
puts 'e.g.'
puts define_hash
eval define_hash
puts ""

puts invert_hash
puts eval(invert_hash).inspect
# => {1 => :a, 2 => :c}

puts ""
puts 'but my new super-duper-hash-invert-erator yields more reasonable results:'
puts 'h.super_duper_invert'
result = 'h.inject({}) {|memo, (k,v)| memo[v] ||= []; memo[v] += [k]; memo}'
puts eval(result).inspect
# => {1 => [:a, :b], 2 => [c]}
