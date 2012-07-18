class Bar
  def self.attach(&b)
    self_of_caller = calling_object(&b)
    puts "calling_object: #{self_of_caller.inspect}"
  end

  # serious Ruby-Fu
  # thx to: http://www.ruby-forum.com/topic/120440
  def self.calling_object(&b)
    eval 'self', b.send(:binding)
  end
end

class Foo
  Bar.attach {}
end

# works in Ruby 1.9.2
class Baz
  Bar.attach
end
