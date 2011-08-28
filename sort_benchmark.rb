#!/usr/bin/env ruby
require 'benchmark'

class Array
  def order_by_sort(ordered_ary)
    self.sort_by{|i| ordered_ary.index(i) || 0 }
  end

  def order_by_amp(ordered_ary)
    ordered_ary & self
  end
end

def gc
  GC.enable
  GC.start
  GC.disable
end

[10, 100, 1000, 10000, 100000, 1000000].each do |n|
  a = Array.new(n) { |i| i }
  ordered_a = a.sort_by { rand }
  k = 1000000 / n
  Benchmark.bm(25) do |bb|
    gc
    bb.report("order_by_amp ("+n.to_s+")    ") do
      k.times do
        a.order_by_amp(ordered_a)
      end
    end
    gc
    bb.report("order_by_sort ("+n.to_s+")   ") do
      k.times do
        a.order_by_sort(ordered_a)
      end
    end
  end
end

#↪ ./sort_benchmark.rb
#                               user     system      total        real
#order_by_amp (10)          0.320000   0.010000   0.330000 (  0.335367)
#order_by_sort (10)         0.590000   0.020000   0.610000 (  0.608281)
#                               user     system      total        real
#order_by_amp (100)         0.310000   0.000000   0.310000 (  0.307471)
#order_by_sort (100)        2.350000   0.010000   2.360000 (  2.353754)
#                               user     system      total        real
#order_by_amp (1000)        0.320000   0.000000   0.320000 (  0.320646)
#order_by_sort (1000)      19.480000   0.020000  19.500000 ( 19.500605)
#                               user     system      total        real
#order_by_amp (10000)       0.360000   0.000000   0.360000 (  0.358560)
#order_by_sort (10000)    194.630000   0.260000 194.890000 (194.805619)
#                               user     system      total        real
#order_by_amp (100000)      0.640000   0.020000   0.660000 (  0.661343)
#order_by_sort (100000)   1913.510000   2.200000 1915.710000 (1915.077870)
#                               user     system      total        real
#order_by_amp (1000000)      1.050000   0.040000   1.090000 (  1.098827)
#order_by_sort (1000000)   ^C./sort_benchmark.rb:6:in `index': Interrupt
