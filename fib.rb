class Fib
  def fib(n)
    @fib ||= {}; @fib[n] ||= begin
                               n <= 1 ? n : fib(n-1) + fib(n-2)
                             end
  end
end
