# require "#{ENV['HOME']}/dev/cmd_notes/can_i_make_a_faster_reduce_for_my_common_usecase"

require 'benchmark'
Enumerable.class_eval do
  def fold(final)
    self.each{|i| final = yield(final, i) }
    final
  end
end

module CompareFoldAndReduce
  extend self

  def sample_data
    [1,2,3,4,5,6,7,8,9,10]
  end

  def num_samples
    100_000
  end

  def motivation
    <<-EOM
    Using pry I discovered that Enumrable#reduce is much more complicated than Enumerable#collect (or #each).
    Although (or because) they're all written in C, I thought I could fashion a faster version of my most common
    use of reduce (aka: inject)
    EOM
  end

  def result_summary
    "no ...at least not like this ...or for my sample data"
  end

  # def action_block
  #   lambda {|memo, i| memo + i}
  # end

  def sample_fold
    sample_data.fold(0) {|memo, i| memo + i}
  end

  def sample_reduce
    sample_data.reduce(0) {|memo, i| memo + i}
  end

  def results
    Benchmark.bmbm do |b|
      b.report("sample_fold") do
        num_samples.times { send("sample_fold") }
      end
      b.report("sample_reduce") do
        num_samples.times { send("sample_reduce") }
      end
    end
  end
end
