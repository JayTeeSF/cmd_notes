#!/usr/bin/env ruby

require 'logger'
class LogTester
  attr_reader :logfile_path, :logger
  def initialize(name)
    @name = name
    @filename = "foo_#{Time.now.to_f}.#{self.object_id}.log" # overkill naming w/ self.object_id
    @logfile_path = "/tmp/#{@filename}"
    @logfile = File.open(@logfile_path, 'a')
    @logger = Logger.new(@logfile)
    puts "\n#{@name}.new Runner(n/a) JobRun(n/a) LogTester(#{self.object_id.inspect}) Ruby-Logger(#{@logger.object_id.inspect}) File(#{@logfile_path})\n"
  end

  def close
    puts "#{@name}#close Runner(n/a) JobRun(n/a) LogTester(#{self.object_id.inspect}) Ruby-Logger(#{@logger.object_id.inspect}) File(#{@logfile_path})\n"
    @logger.info "---closed #{@filename} at #{Time.now}---"
    @logger.close
    @logfile_path
  end
end

class JobRun
  def initialize(name)
    @name = name
  end

  def start(name)
    @lt = LogTester.new(name)
    print "#{name}#start Runner(n/a) JobRun(#{self.object_id.inspect}) LogTester(#{@lt.object_id.inspect}) Ruby-Logger(#{@lt.logger.object_id.inspect}) "
    print "File("
    file_path  = @lt.logger.logfile_path rescue "???"
    print file_path
    puts ")\n"
    self
  end

  def lt
    @lt
  end

  def stop(status)
    print "\n#{@name}#stop Runner(n/a) JobRun(#{self.object_id.inspect}) LogTester(#{@lt.object_id.inspect}) Ruby-Logger(#{@lt.logger.object_id.inspect}) "
    print "File("
    file_path = @lt.logger.logfile_path rescue "???"
    print file_path
    puts ")\n"
    @lt.close
    puts "\t---> close #{@lt.logfile_path}:"
    puts "\t\t#{IO.read(@lt.logfile_path).gsub(/\n/,"\n\t\t")}"
  end
end

class Runner
  def self.run(name, &block)
    new(name).run(&block)
  end

  def initialize(name)
    @name = name
    @job = JobRun.new(@name)
  end

  def run(&block)
    # the inner block overrides the definition of @job, when it runs!
    # @job = JobRun.new(@name).start # moved this out of begin-ensure-end
      @job.start(@name) # moved this out of begin-ensure-end
    begin
      print "#{@name}.run-pre-yield Runner(#{self.object_id.inspect}) JobRun(#{@job.object_id.inspect}) LogTester(#{@job.lt.object_id.inspect}) Ruby-Logger(#{@job.lt.logger.object_id.inspect}) "
      print "File("
      file_path = @job.lt.logger.logfile_path rescue "???"
      print file_path
      puts ")\n"
      yield(@job) if block_given?
    ensure
      print "#{@name}.run-post-yield Runner(#{self.object_id.inspect}) JobRun(#{@job.object_id.inspect}) "
      print "LogTester("
      log_tester = @job.lt.object_id.inspect rescue "???"
      print log_tester
      print ") "
      print "Ruby-Logger(#{@job.lt.logger.object_id.inspect}) "
      print "File("
      file_path = @job.lt.logger.logfile_path rescue "???"
      print file_path
      puts ")\n"
      @job.stop("ok")
    end
    # @job
  end
end

if __FILE__ == $PROGRAM_NAME
  def outer_runner
    Runner.run('Outer Runner-') do |job|
      logger = job.lt.logger
      print "Outer Runner-block 1: Runner(unk) JobRun(#{job.object_id.inspect}) LogTester(#{job.lt.object_id.inspect}) Ruby-Logger(#{job.lt.logger.object_id.inspect}) "
      print "File("
      file_path = @job.lt.logger.logfile_path rescue "???"
      print file_path
      print ") "
      puts "logger(#{logger.object_id.inspect})\n"
      logger.info "#{Time.now}: Starting outer runner\n"
      inner_runner
      logger.info "#{Time.now}: Finished outer runner, and now job: #{job.object_id.inspect}"
      print "Outer Runner-block 2: Runner(unk) JobRun(#{job.object_id.inspect}) LogTester(#{job.lt.object_id.inspect}) Ruby-Logger(#{job.lt.logger.object_id.inspect}) "
      print "File("
      file_path = @job.lt.logger.logfile_path rescue "???"
      print file_path
      print ") "
      puts "logger(#{logger.object_id.inspect})\n"
     ### File(#{job.lt.logger.logfile_path}) logger(#{logger.object_id.inspect})\n"
    end
  end

  def inner_runner
    Runner.run('Inner Runner-') do |job|
      logger = job.lt.logger
      print "Inner Runner-block 1: Runner(unk) JobRun(#{job.object_id.inspect}) LogTester(#{job.lt.object_id.inspect}) Ruby-Logger(#{job.lt.logger.object_id.inspect}) "
      print "File("
      file_path = @job.lt.logger.logfile_path rescue "???"
      print file_path
      print ") "
      puts "logger(#{logger.object_id.inspect})\n"
      logger.info "#{Time.now}: Starting inner runner"
      logger.info "#{Time.now}: Finished inner runner"
      print "Inner Runner-block 2: Runner(unk) JobRun(#{job.object_id.inspect}) LogTester(#{job.lt.object_id.inspect}) Ruby-Logger(#{job.lt.logger.object_id.inspect}) "
      print "File("
      file_path = @job.lt.logger.logfile_path rescue "???"
      print file_path
      print ") "
      puts "logger(#{logger.object_id.inspect})\n"
    end
  end

  outer_runner
end
