Try to return a single object from every method.

Try not to return multiple values from a method.
That typically defeats the "single responsibility" principle.

However, there are times when you have an expensive operation that you would _otherwise_ need to call multiple times.
In these cases, still only return one value, but (in Ruby) create and return a Struct.
The Struct saves state and then allows the caller to manipulte _it_ in order to access the various pieces of information.

x = get_a_and_b
do_something if x.a == true
...
do_something_else if x.b == true

# bad:
def get_a_and_b
   ...
  return [a, b]
end

# better:
def get_a_and_b
  ...
  return Struct.new(:a => xxx, :b => yyy)
end


On the other hand, if you can simply do:
def get_a
 a
end
def get_b
 b
end

Do that instead!
