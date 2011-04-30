#!/usr/bin/env ruby

require 'digest/md5'
require 'digest/sha1'


class Hasher
  BUFLEN = 1024
  # Constructor
  # method = "SHA1" or "MD5"
  # filepath = Full filepath
  def initialize(method, filepath)
    if (method.upcase == "-SHA1")
      @hashfunc = Digest::SHA1.new
      @hashname = "SHA1"
    else
      @hashfunc = Digest::MD5.new
      @hashname = "MD5"
    end
    @fullfilename = filepath
  end

  def hashname
    @hashname
  end

  # Compute hash code
  def hashsum
    open(@fullfilename, "r") do |io|
      # puts "Reading "+@fullfilename
      counter = 0
      while (!io.eof)
        readBuf = io.readpartial(BUFLEN)
        # putc '.' if ((counter+=1) % 3 == 0)
        @hashfunc.update(readBuf)
      end
    end
    return @hashfunc.hexdigest
  end

  def self.usage
    puts "Usage: Hasher.rb [-SHA1|-MD5] filename"
  end

  def self.printresult(filename, method, sum)
    puts "\n" + filename + " ==> "+ method + ": " + sum  
  end
end

module HashUtil
  extend self

  def invert(h={})
    h.inject({}) {|memo, (k,v)| memo[v] ||= []; memo[v] += [k]; memo}
  end
end

path_prefix = ARGV[0]
unless path_prefix
  puts "Please provide location of root dir, e.g.: /???/iPhoto\ Library"
  exit
end
  # "#{path_prefix}/**/*.JPG",
  # "#{path_prefix}/**/*.jpg"
file_hash = Dir[
  "#{path_prefix}/**/*"
].inject({}) do |memo, file_path|
  memo[file_path] = Hasher.new("-SHA1", file_path).hashsum
  memo
end

#puts "#{file_path} hash: #{hash} vs. openssl: " + %x{openssl dgst -sha1 #{file_path}}

duplicate_hash = HashUtil.invert(file_hash).select {|h,k| k.size > 1}

duplicate_hash.each do |sha1, file_path_ary|
  puts ""
  file_path_ary.each_with_index do |file_path, idx|
    print (0 < idx) ?  "rm " : "# save: "
    puts "#{file_path};"
  end
end

#Program starts
#if (ARGV.length == 2)
#  hashcomp = Hasher.new(ARGV[0], ARGV[1])
#  Hasher.printresult(ARGV[1], hashcomp.hashname, hashcomp.hashsum)
#  
#elsif (ARGV.length == 1)
#  hashcomp = Hasher.new("-MD5", ARGV[0])
#  Hasher.printresult(ARGV[0], hashcomp.hashname, hashcomp.hashsum)
#else
#  Hasher.usage
#end

