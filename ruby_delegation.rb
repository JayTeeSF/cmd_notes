# Given an Env class with "foo" and "bar" method(s)
class Env; def foo(opts={}); puts "foo #{opts.inspect}"; end; def bar(opts={}); puts "bar #{opts.inspect}"; end; end

# You can wrap an instance of Env
# delegating calls to all of it's methods except "foo"
# which exists in the EnhancedEnv class
# Of course, you could always override the retained and delegable methods
# to get different results
class EnhancedEnvironment
  def foo(opts={}); puts "enhanced foo: #{opts.inspect}"; end

  def _eigenclass
    class << self; self; end
  end

  def initialize(env)
    @env = env
    delegated_methods.each do |meth|
      _eigenclass.class_eval do
        define_method(meth) do |*args|
          @env.send meth, *args
        end
      end
    end
  end

  def retained_methods
    public_methods(false)
  end

  def delegated_methods
    delegable_methods - retained_methods
  end

  def delegable_methods
    @env.public_methods(false)
  end
end

# ee = EnhancedEnvironment.new(Env.new)
# 2.2.1 :002 > ee.bar
# bar {}
# => nil

# 2.2.1 :003 > ee.foo
# enhanced foo: {}
# => nil

