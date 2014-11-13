class T

  def self.block_to_print_name
    lambda {|t| puts "block printing t.name: #{t.name}" }
  end

  def self.create_and_copy_without_passing_block(_name)
    puts "creating initial instance..."
    it = new(_name)
    puts "done creating initial instance."

    puts "copying initial instance..."
    it.copy_without_block("#{_name} copied", &block_to_print_name)
    puts "done copying initial instance."
  end

  def self.create_and_copy_passing_block(_name, &block)
    puts "creating initial instance..."
    it = new(_name)
    puts "done creating initial instance."

    puts "copying initial instance..."
    it.copy_with_block("#{_name} copied", &block)
    puts "done copying initial instance."
  end

  attr_reader :name
  def initialize(name)
    @name = name
    if block_given?
      puts "gonna yield:"
      yield(self)
      puts "...done with any yield(s)."
    end
  end

  def copy_without_block(_name=@name)
    self.class.new(_name)
  end

  def copy_with_block(_name=@name, &block)
    self.class.new(_name, &block)
  end

  def some_method(new_name=nil, &block)
    message = block_given? ? "block given" : "no block given"
    puts message + " name_arg: #{new_name.inspect}"
  end
end
