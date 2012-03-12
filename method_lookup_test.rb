module BarMethods
  def speak(msg="mod ")
    msg + (defined?(super) ? super() : "")
  end
end

class Bar
  include BarMethods
  def speak(msg="bar-instance ")
    msg + (defined?(super) ? super() : "")
  end
end

b = Bar.new
b.speak
module BM; include BarMethods; end
b.extend BM # does changing the constant name work ?!
puts b.speak

# apparently we can't extend the same module on an instance
# if the class already included that module (i.e. it's a no-op)
# I guess this is similar to how Ruby won't let you re-include
# a module that's already been included

module WithSpeakInstanceExtension
  def speak(msg="instance-extension speaking")
    msg + (defined?(super) ? super() : "")
  end
end

module WithSpeakClassInclusion
  def speak(msg="class-inclusion speaking")
    msg + (defined?(super) ? super() : "")
  end
end

module WithSpeakClassExtension
  def speak(msg="class-extension speaking")
    msg + (defined?(super) ? super() : "")
  end
end

class Foo
  include WithSpeakClassInclusion
  extend WithSpeakClassExtension # not called anyway ...since this creates a "Class" method (not an instance method)

  def speak(msg="foo-instance speaking... ")
    msg="foo-instance speaking... "
    msg + (defined?(super) ? super() : "")
  end
end

f = Foo.new
puts f.speak

f.extend WithSpeakInstanceExtension # not sure ?! -- probably overwrote class-inclusion ?!
# f.include Speak # undefined method 'include' for <Foo...>

puts f.speak

def f.speak(msg="before foo-instance-extension speaking... ")
  msg + (defined?(super) ? super() : "")
end
puts f.speak # worked!
