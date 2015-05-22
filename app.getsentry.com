I can never remember the url to this site.
Also, here's a snippet of code to trigger it:

class Foo; def bar; fail("just cuz I'm testing"); rescue Exception => e; Raven.capture_exception(e); end; end
Foo.new.bar
# ** [Raven] Event not sent due to excluded environment: development
#  => true
