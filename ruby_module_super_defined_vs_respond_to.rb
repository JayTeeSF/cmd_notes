class A
  def self.sp
    "\tAok"
  end
end

class Achild < A
end

class C < Achild
  def self.sp
    (respond_to?(super) ? super + " and Cok" : "\tCnok")
  end
end

class D < C
  def self.sp
    (respond_to?(super) ? super + " and Dok" : "\tDnok")
  end
end

#### VS. (thanks to: http://stackoverflow.com/questions/10808/ruby-mixins-and-calling-super-methods)

class Aprime
  def self.sp
    "\tAprimeok"
  end
end

class Aprimechild < Aprime
end

class Cprime < Aprimechild
  def self.sp
    (defined?(super) ? super + " and Cprimeok" : "\tCprimenok")
  end
end

class Dprime < Cprime
  def self.sp
    (defined?(super) ? super + " and Dprimeok" : "\tDprimenok")
  end
end

#
puts A.sp
#  Aok
puts Achild.sp
#  Aok
puts C.sp
#  Cnok
puts D.sp
#  Dnok

puts Aprime.sp
#  Aprimeok
puts Aprimechild.sp
#  Aprimeok
puts Cprime.sp
#  Aprimeok and Cprimeok
puts Dprime.sp
#  Aprimeok and Cprimeok and Dprimeok


#
