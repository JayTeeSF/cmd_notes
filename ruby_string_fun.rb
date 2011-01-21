module TextFun 
  extend self

  # debug only:
  def inspect_string(str)
    puts str + ": "
    str.split(//).each do |c| 
      c_num = c[0]
      puts "c: #{c.inspect} => #{c_num}; #{c_num.chr}"
    end
  end
end

# useful for identifying special (hidden) characters within a string
str = "this is a test" + "FdAÂ in"
TextFun.inspect_string(str)
