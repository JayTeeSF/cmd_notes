#!/usr/bin/env ruby

class PrintCode
  DEFAULT_SKIP_PATTERNS = [ /^#!\//, /#IGNORE\s*$/ ]
  DEFAULT_BREAK_PATTERNS = [ /^__END__/ ]
  DEFAULT_FILE_METHODS = ["rewind", "gets"]
  DEFAULT_FILE_CLASS_METHODS = ["open"]
  DEFAULT_FILE_MODE =  "r"

  def self.usage
    x=<<-EOM
    irb -r ./print_code.rb
    pc = PrintCode.new("some_code.rb")
    puts pc.source
    EOM
  end
  def self.example
    puts PrintCode.new.source #IGNORE
  end

  # EXAMPLE USAGE: puts PrintCode.new.source
  attr_reader :break_patterns, :skip_patterns, :file, :file_class, :file_methods, :file_class_methods, :file_mode
  def initialize file_or_path = nil, options = {}
    @break_patterns = options[:break_patterns] || DEFAULT_BREAK_PATTERNS
    @skip_patterns = options[:skip_patterns] || DEFAULT_SKIP_PATTERNS
    @file_class_methods = options[:file_class_methods] || DEFAULT_FILE_CLASS_METHODS
    @file_methods = options[:file_methods] || DEFAULT_FILE_METHODS
    @file_class = options[:file_class] || File
    raise ArgumentError, "file_class: #{@file_class.inspect} doesn't support one or more #{file_class_methods.inspect}" unless fully_supports?( file_class, file_class_methods )
    @file_mode = options[:mode] || DEFAULT_FILE_MODE
    file_or_path ||= __FILE__
    @file = file_or_path if fully_supports?( file_or_path, file_methods )
    @file ||= file_class.send( file_class_method("open"), file_or_path, file_mode )
  end

  def file_method( name )
    raise RuntimeError, "Unknown file_method #{name.inspect} called" unless file_methods.include?( name )
    name
  end

  def file_class_method( name )
    raise RuntimeError, "Unknown file_class_method #{name.inspect} called" unless file_class_methods.include?( name )
    name
  end

  def source
    "".tap do |_source|
      file.send( file_method("rewind") )
      while line = file.send( file_method("gets") )
        break if break_patterns.any?{ |pattern| line[pattern] }
        next if skip_patterns.any?{ |pattern| line[pattern] }
        _source << line
      end
    end
  end

  def fully_supports?( obj, methods = [] )
    methods.all?{ |method_name| obj.respond_to?( method_name ) }
  end
end

if __FILE__ == $PROGRAM_NAME
  puts "USAGE: #{PrintCode.usage}\n"

  puts "Begin Example:"
  puts "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  PrintCode.example
  puts "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  puts "End Example"
end
