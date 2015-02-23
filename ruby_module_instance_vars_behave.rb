module C
  def cached_attrs
    unless @cached_attrs
      @cached_attrs = self.attrs
    end
    @cached_attrs
  end
end
# => :cached_attrs
puts "module C caches self.attrs in @cached_attrs via its cached_attrs method"

class A
  include C
  def attrs
    [:a1, :a2, :a3]
  end
end
# => :attrs
puts "class A includes C and implements an attrs method"

class B
  include C
  def attrs
    [:b1, :b2, :b3]
  end
end
# => :attrs
puts "class B includes C and implements an attrs method"

a = A.new
# => #<A:0x007fc9211e4528>
b = B.new
# => #<B:0x007fc9211c6410>
puts "Does an instance of A correctly cache it's own attrs?"
puts (a.cached_attrs == a.attrs ? "yes" : "no!")
# => [:a1, :a2, :a3]

puts "Does an instance of B correctly cache it's own attrs?"
b.cached_attrs
puts (b.cached_attrs == b.attrs ? "yes" : "no! perhaps it get's what a already cached: #{b.cached_attrs}")
#=> [:b1, :b2, :b3]
