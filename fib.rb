# irb -r "./fib.rb"
# Fib.test
# or
# f = Fib.new(debug=true); f.fib(3)

class Fib
  def self.test
    f = Fib.new(true)

    f.debug { "trying 3" }
    f.fib(3)

    f.debug { "trying 33" }
    f.fib(33)

    f.debug { "trying 99" }
    f.fib(99)
  end

  def initialize(debug=false)
    @debug = debug
  end

  def fib(n)
    unless @fib
      debug { "first time" }
      @fib = {}
    end

    unless @fib[n]
      debug { "calculating fib for #{n}" }
      @fib[n] = (n <= 1) ? n : fib(n-1) + fib(n-2)
    end

    result = @fib[n]
    debug { "(#{n}) #{result.inspect}" }
    result
  end

  def debug?
    !!@debug
  end

  def debug
    return unless debug?
    puts(yield) if block_given?
  end
end
