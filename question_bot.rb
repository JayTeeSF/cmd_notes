#!/usr/bin/env ruby

require 'rubygems'
require 'net/toc'
require ENV["HOME"] + "/bin/secure_settings.rb"

class GitRepo
  DEFAULT_BASE_PATH = '/tmp' # you may want to move this ;-)
  ALL_FILES = ".".freeze

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

  def destination_dir(sub_dir=nil)
    destination_dir = working_dir
    destination_dir += "/#{sub_dir}" if sub_dir
  end

  def commit filename, sub_dir=nil
    chdir destination_dir(sub_dir)
    add filename, sub_dir
    %x/git commit -m "commiting #{filename}"/
  end

  def add filename=ALL_FILES, sub_dir=nil
    _dir = destination_dir(sub_dir)
    file_path = _dir + "/#{filename}"
    unless ALL_FILES == filename || File.exists?(file_path)
      raise RuntimeError, "missing file: #{file_path}"
      return
    end
    chdir(_dir)
    %x/git add #{filename}/ 
  end

  private

  def chdir(_dir=nil)
    return unless _dir
    Dir.chdir(_dir)
  end

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

  HELP_CMD = "help"
  LIST_CMD = "list"
  REGISTER_CMD = "register"
  SHOW_CMD = "show"
  UNKNOWN_CMD = 'Unknown cmd'

  HTML_TAB = "&nbsp;&nbsp;&nbsp;"
  HTML_GT = "&gt;"
  HTML_LT = "&lt;"

  SPECIAL_CHAR_REPLACEMENT = '_'

  def init
    @db = GitRepo.new("questions_db")
    @db.init
    @next_question_id = 1 + Dir[@db.working_dir + "/**/*.#{QUESTION_FILE_SUFFIX}"].count
  end

  # Filters:
  #   :id => ...
  #   :owner => ...
  #   :type => ...
  def list_questions filters={}
    question_files(filters).map do |filename|
      just_the_name(filename) + " => " + extract_question(filename)
    end
  end

  def show_question filters={}
    filename = question_files(filters).first
    [extract_question(filename)]
  end

  def register_question question, owner
   filename = sanitize_filename("#{next_question_id}_by_#{owner}.#{QUESTION_FILE_SUFFIX}")
   puts "storing the following question: #{question} in #{filename}..."
   open_question(filename, {:question => question, :author => owner})
   ["ok"]
  end

  def open_question filename, content
    unless File.exists?(file_dir(OPEN))
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

  def append_answer_to_file filename, content
    raise NotImplementedError, "Coming Soon..."
  end

  # returns an array of messages to reply with
  def process cmd, owner
    debug { "got: cmd: #{cmd} by owner: #{owner}" }
    filters = {}

    case cmd
    when /^#{HELP_CMD}\s*$/i
      cmd_info
    when /^#{REGISTER_CMD}\:\s+([^\?]+\?)/i
     register_question($1, owner)
    when /^#{LIST_CMD}(?:\s*|\:\s+([\w]+)(?:|\s+([\w]+)))\s*$/i
     whose = $1; q_type = $2
     filters[:type] = q_type if Q_TYPES.member?(q_type)
     if whose == MINE
       filters[:owner] = sanitize_filename owner
     elsif authorized.member?(whose)
       filters[:owner] = sanitize_filename whose
     end

     list_questions filters
    when /^#{SHOW_CMD}(?:|\:)\s+([\d]+)\s*$/i
      filters[:id] = $1
      show_question filters
    else
      [UNKNOWN_CMD]
    end
  end

  protected

  # TODO: create a Message Class that encapsulates & handles all of this...
  def add_html message
    message.gsub(/</,HTML_LT).gsub(/>/,HTML_GT).gsub(/\t/,HTML_TAB)
  end

  def strip_html message
    message.chomp.gsub(/<[^>]+>/,"")
  end

  def sanitize_filename str
    str.strip.tap do |name|
      name = replace_special_chars(remove_invalid_chars(name))
    end
  end

  private

  def just_the_name(filename)
    File.basename(filename, File.extname(File.basename(filename)))
  end
  def replace_special_chars(str)
    str.gsub(/[^0-9A-Za-z.\-]/, SPECIAL_CHAR_REPLACEMENT)
  end

  def remove_invalid_chars(str)
    str.gsub(/^.*(\\|\/)/, '')
  end

  attr_reader :next_question_id

  def cmd_info
    [
      HELP_CMD,
      "#{REGISTER_CMD}: some question?",
      "#{LIST_CMD}|#{LIST_CMD}: <owner>|#{LIST_CMD}: <owner> <q_type>",
      "#{SHOW_CMD}: <id>",
      "\t<owner>: #{MINE} | #{authorized.join(" | ")}",
      "\t<q_type>: #{Q_TYPES.join(" | ")}"
    ]
  end

  def question_files filters={}
    filters = DEFAULT_OPEN_FILTERS.merge(filters)
    Dir[file_path(filters[:id] + "_by_#{filters[:owner]}.#{QUESTION_FILE_SUFFIX}", filters[:type])]
  end

  def extract_question filename
    (File.open(filename).find &match_question).chomp
  end

  def match_question 
    lambda {|line| line =~ /^#{QUESTION_PREFIX}/ }
  end

  def incr
    @next_question_id += 1
  end

  def file_dir sub_dir
    "#{@db.working_dir}/#{sub_dir}"
  end

  def file_path file_name, sub_dir
    "#{file_dir(sub_dir)}/#{file_name}"
  end

end

class Bot
  include BotCommander
  include SecureSettings
  QUIT_CMDS = ['quit', 'exit', 'Exit', 'Quit']
  BUDDY_PROMPT = "buddy: "
  MESSAGE_PROMPT = "message: "
  EXIT_MESSAGE = "later on..."

  IGNORE_MESSAGE = "I am not authorized to talk to you. ...I am ignoring you."

  attr_reader :user, :authorized
  attr_accessor :verbose

  def initialize(user=nil, pwd=nil, authorized=nil, verbose=false)
    @user = user || USER
    @pwd = pwd || PWD
    @authorized = authorized || AUTHORIZED
    @verbose = verbose
  end

  def test
    init
    buddy = prompt BUDDY_PROMPT
    if authorized.member? buddy
      begin
        message = strip_html( prompt(MESSAGE_PROMPT) )
        begin
          process(message, buddy) do |line|
            # puts "send_im: #{add_html(line)}"
            puts "send_im: #{line}"
          end
        rescue Exception => e
          puts handle(e, message)
        end
        puts
      end while true
    else
      puts IGNORE_MESSAGE
    end
  end

  def start
    init
    result = Net::TOC.new(user, pwd) do |message, buddy|
      debug { "message: #{message}; buddy: #{buddy}" }
      if authorized.member? buddy.screen_name
        begin
          message = strip_html(message)
          process(message, buddy.screen_name) do |line|
            # TBD: split line if it's too long
            # TBD: discover the definition of: too long
            buddy.send_im add_html(line)
          end
        rescue Exception => e
          buddy.send_im handle(e, message)
        end
      else
        buddy.send_im add_html(IGNORE_MESSAGE)
      end
    end
    puts "result: #{result.inspect}"
  rescue Exception => e
    puts "e: #{e}"
  end

  # should this be protected ?
  def process(message, screen_name)
    exit if exit?(message)
    result = super(message, screen_name)
    # puts "result: #{result.inspect}"
    result.each do |line|
      # puts "line: #{line.inspect}"
      line.to_s! if line.respond_to?(:to_s!)
      yield line if block_given?
    end
  end

  private

  attr_reader :pwd

  def verbose?
    verbose
  end

  def debug &block
    puts yield if verbose?
  end

  def prompt(msg)
    print msg
    gets.chomp.tap do |response|
      puts
    end
  end

  def goodbye
    puts EXIT_MESSAGE
    exit
  end

  def handle(e, message="")
    goodbye if exit?(message)
    "#{e.class}: #{e}"
  end

  def exit?(message)
    QUIT_CMDS.member? message
  end

end

def self.usage
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
      #{$0}

  To run in test-mode: #{$0} #{TEST_OPTION}

  To see this message, again: #{$0} #{HELP_OPTION}
  EOM
end

def self.flush_input
  begin
    ARGV.shift
  end until ARGV.empty?
end

TEST_OPTION = 'test'
HELP_OPTION = '--help'
UNKNOWN_OPTION = 'Unknown option...'
# do_it...
case ARGV[0]
  when nil
    Bot.new.start    
  when TEST_OPTION
    flush_input
    Bot.new.test
  when HELP_OPTION
    usage
  else
    puts UNKNOWN_OPTION
    usage
end