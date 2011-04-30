#!/usr/bin/env ruby

require 'rubygems'
require 'net/toc'
require ENV["HOME"] + "/bin/secure_settings.rb"

class GitRepo
  DEFAULT_BASE_PATH = '/tmp'

  attr_reader :base_path, :name, :working_dir, :index

  def initialize( _name, _base_path=DEFAULT_BASE_PATH )
    @base_path = _base_path
    @name = _name
    @working_dir = "#{base_path}/#{name}"
    @index = "#{base_path}/#{name}/.git"
  end

  def init
    unless File.exists?(index)
      Dir.chdir base_path
      %x/git init #{name}/
    end
  end

  def commit filename, sub_dir=nil, message=nil
    storage_dir = working_dir
    storage_dir += sub_dir if sub_dir
    Dir.chdir storage_dir
    add filename
    message ||= "commiting #{filename}"
    %x/git commit -m #{message}/
  end

  ALL_FILES = ".".freeze
  def add filename=ALL_FILES
    file_path = working_dir + "/#{filename}"
    unless ALL_FILES == filename || File.exists?(file_path)
      raise RuntimeError, "missing file: #{file_path}"
      return
    end
    %x/git add #{filename}/ 
  end
  private :add

end

module BotCommander
  OPEN = "open"
  CLOSE = "close"
  Q_TYPES = [OPEN, CLOSE]

  QUESTION_FILE_SUFFIX = "qst"
  DEFAULT_OPEN_FILTERS = {:id => "*", :owner => "*", :type => OPEN}.freeze
  QUESTION_PREFIX = "Question:"
  AUTHOR_PREFIX = "Author:"
  MINE = "mine"

  attr_reader :next_question_id

  def init
    @db = GitRepo.new("questions_db")
    @db.init
    @next_question_id = 1 + Dir[@db.working_dir + "/*.#{QUESTION_FILE_SUFFIX}"].count
  end

  # Filters:
  #   :id => ...
  #   :owner => ...
  #   :type => ...
  def list_questions filters={}
    question_files(filters).inject({}) do |memo, filename|
      memo[filename] = extract_question(filename)
      memo
    end
  end

  def question_files filters={}
    filters = DEFAULT_OPEN_FILTERS.merge(filters)
    Dir[file_path(filters[:id] + "_by_#{filters[:owner]}.#{QUESTION_FILE_SUFFIX}", filters[:type])]
  end
  private :question_files

  def show_question filters={}
    filename = question_files(filters).first
    [extract_question(filename)]
  end

  def extract_question filename
    File.open(filename).find &match_question
  end

  def match_question 
    lambda {|line| line =~ /^#{QUESTION_PREFIX}/ }
  end

  def register_question question, owner
   filename = sanitize_filename("#{next_question_id}_by_#{owner}.#{QUESTION_FILE_SUFFIX}")
   puts "create file (#{filename}) in repo w/ following question: #{question}"
   open_question(filename, {:question => question, :author => owner})
   ["ok"]
  end

  def incr
    @next_question_id += 1
  end
  private :incr

  def append_answer_to_file filename, content
    raise NotImplementedError, "Coming Soon..."
  end

  def file_dir file_name, sub_dir
    "#{@db.working_dir}/#{sub_dir}"
  end

  def file_path file_name, sub_dir
    "#{file_dir}/#{file_name}"
  end

  def open_question filename, content
    unless File.exists?(file_dir)
      Dir.chdir @db.working_dir
      Dir.mkdir OPEN
    end
    File.open(file_path(filename, OPEN), "w") do |f|
      f.puts "#{QUESTION_PREFIX} #{content[:question]}"
      f.puts "#{AUTHOR_PREFIX} #{content[:author]}"
    end
    @db.commit(filename, OPEN)
    incr
  end

  def sanitize_filename str
    str.strip.tap do |name|
      name.gsub!(/^.*(\\|\/)/, '')
      name.gsub!(/[^0-9A-Za-z.\-]/, '_')
    end
  end
 
  def process cmd, owner
    puts "got: cmd: #{cmd} by owner: #{owner}"
    filters = {}

    case cmd
    when /^help\s*$/i
      puts "helping..."
      cmd_info
    when /^register\:\s+([^\?]+\?)/i
     register_question($1, owner)
    when /^list(?:\s*|\:\s+([\w]+)(?:|\s+([\w]+)))\s*$/i
     whose = $1; q_type = $2
     filters[:type] = q_type if Q_TYPES.member?(q_type)
     if whose == MINE
       filters[:owner] = sanitize_filename owner
     elsif authorized.member?(whose)
       filters[:owner] = sanitize_filename whose
     end

     list_questions filters
    when /^show\:\s+([\d]+)\s*$/i
      filters[:id] = $1
      show_question filters
    else
      ['unknown cmd']
    end
  end

  def cmd_info
    [
      "help",
      "register: some question?",
      "list|list: <owner>|list: <owner> <q_type>",
      "show: <id>",
      "\t<owner>: #{MINE} | #{authorized.join(" | ")}",
      "\t<q_type>: #{Q_TYPES.join(" | ")}"
    ]
  end

  def message_to_command message
    message.chomp.gsub(/<[^>]+>/,"")
  end
end

class Bot
  include BotCommander
  include SecureSettings
  QUIT_CMDS = ['quit', 'exit', 'Exit', 'Quit']

  attr_reader :user, :authorized, :pwd
  private :pwd

  def initialize(user=nil, pwd=nil, authorized=nil)
    @user = user || USER
    @pwd = pwd || PWD
    @authorized = authorized || AUTHORIZED
  end

  def test
    init
    print "buddy: "
    buddy = gets.chomp
    if authorized.member? buddy
      begin
        puts
        print "message: "
        message = gets.chomp
        puts
        begin
          do_it(message, buddy) do |line|
            puts "result-line: #{line}"
          end
        rescue Exception => e
          puts handle(e, message)
        end
      end while true
    end
  end

  def handle(e, message="")
    exit if exit?(message)
    "#{e.class}: #{e}"
  end
  private :handle

  def exit?(message)
    QUIT_CMDS.member? message
  end

  def do_it(message, screen_name, &block)
    exit if exit?(message)
    result = process(message, screen_name)
    result.each do |line|
      line.to_s! if line.respond_to?(:to_s!)
      yield line if block_given?
    end
  end
  private :do_it

  def start
    init
    Net::TOC.new(user, pwd) do |message, buddy|
      if authorized.member? buddy.screen_name
        begin
          message = message_to_command(message)
          do_it(message, buddy.screen_name) do |line|
            buddy.send_im line
          end
        rescue Exception => e
          buddy.send_im handle(e, message)
        end
      end
    end
  end
end

# do_it...
case ARGV[0]
  when 'do_it'
    Bot.new.start
  when '--help'
    puts <<-EOM
    to run this bot:
    (a) gem install net-toc

    (b) setup at least 2 AIM account(s):
        o one for this BOT
        o (at least) one from which to control this BOT

    (c) Create your own #{ENV['HOME']}/bin/secure_settings.rb file, e.g.:
        module SecureSettings
          AUTHORIZED = ["your_AIM_screen_name"].freeze
          USER='AIM_screen_name_for_your_bot'.freeze
          PWD='AIM_pwd_for_your_bot'.freeze
        end

    and
    (d) chmod +x the file and run it again, as:
        #{$0} do_it

    Note: if you run it without any options, it will run in an interactive cmdline (test) mode.
    EOM
  else
    Bot.new.test
end