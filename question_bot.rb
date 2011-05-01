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
  OPEN_QTYPE = "open"
  CLOSE_QTYPE = "closed"
  ALL_QTYPE = "all"
  Q_TYPES = [OPEN_QTYPE, CLOSE_QTYPE, ALL_QTYPE]

  FILE_SUFFIX = "qst"
  DEFAULT_OPEN_FILTERS = {:id => "*", :owner => "*", :type => OPEN_QTYPE}.freeze
  QUESTION_PREFIX = "Hmm..."
  ANSWER_PREFIX = "One Answer is:"
  RESPONDENT_PREFIX = "...says,"
  AUTHOR_PREFIX = "...asks,"
  OWNER_PREFIX = "_by_"

  MINE = "mine"

  HELP_CMD = "help"
  ANSWER_CMD = "answer"
  REGISTER_CMD = "register"
  SHOW_CMD = "show"
  CLOSE_CMD = "close"
  UNKNOWN_CMD = "Unknown cmd"
  ANSWERS_TOO = "ans"

  HTML_TAB = "&nbsp;&nbsp;&nbsp;"
  HTML_GT = "&gt;"
  HTML_LT = "&lt;"

  SPECIAL_CHAR_REPLACEMENT = '_'

  UNKNOWN_QUESTION_ERROR = "Unknown Question"
  NO_QUESTIONS_FOUND = "No Questions"

  CLOSED_OK = "closed."
  REGISTERED_OK = "hold that thought."

  def init
    @db = GitRepo.new("questions_db")
    @db.init
    @next_question_id = 1 + Dir[@db.working_dir + "/**/*.#{FILE_SUFFIX}"].count
  end

  # Filters:
  #   :id => ...
  #   :owner => ...
  #   :type => ...
  def show_questions filters={}
    files = question_files(filters)
    results = files.map do |filename|
      _id_and_descr = id_and_description filename
      debug { filters[:answers_too] ? "filters TOO" : "NO FILTERS" }

      questions = extract_questions(filename, filters[:answers_too])

      unless _id_and_descr || questions
        nil
      else
        [_id_and_descr + " => " + questions.first] +        
        questions[1..-1].collect do |question|
          "\t => " + question
        end
    end
    end.compact
    return results.empty? ? [NO_QUESTIONS_FOUND] : results
  end

  def close_question filters={}
    file_path = question_files(filters).first
    return [UNKNOWN_QUESTION_ERROR] unless file_path

    destination_dir = @db.destination_dir(CLOSE_QTYPE)
    unless File.exists?(destination_dir)
      Dir.chdir @db.working_dir
      Dir.mkdir CLOSE_QTYPE
    end
    destination_file = File.basename(file_path)
    destination_path = File.join(destination_dir, destination_file)

    # FIXME: create DBAdapter class (to wrap @db) which responds to CRUD
    # it should be (secretly) responsible for any file-mgmt
    # also:
    # FIXME: git-mv (vs. system-mv the file); add -u (changes); and commit
    File.rename file_path, destination_path

    @db.commit(destination_file, CLOSE_QTYPE)
    [CLOSED_OK]
  end

  def register_question question, owner
   filename = sanitize_filename("#{next_question_id}#{OWNER_PREFIX}#{owner}.#{FILE_SUFFIX}")
   debug { "storing the following question: #{question} in #{filename}..." }
   open_question(filename, {:question => question, :author => owner})
   [REGISTERED_OK]
  end

  def answer_question answer, author, filters={}
    # can't answer closed questions
    filename = question_files(filters).first
    return [UNKNOWN_QUESTION_ERROR] unless filename

    debug { "storing the following answer: #{answer} in #{filename}..." }
    append_answer_to_file(filename, {:answer => answer, :author => author})
  end

  # returns an array of messages to reply with
  def process cmd, owner
    debug { "got: #{cmd} from: #{owner}" }
    filters = {}

    case cmd
    when /^#{HELP_CMD}\s*$/i
      cmd_info

    when /^(?:|#{REGISTER_CMD})(?:|\:\s+)\s*([^\?]+\?)\s*$/i
      question = $1
      register_question(question, owner)

    when /^(?:|#{ANSWER_CMD})(?:|\:\s+)\s*([\d]+)\s+(.+\.)\s*$/i
      filters[:id] = $1; answer = $2
      answer_question answer, owner, filters

    when /^(?:|#{SHOW_CMD})(?:|\:\s+)\s*([\d]+|(?:#{Q_TYPES.join("|")})+(?:|\s+([\w]+)))(?:|\s+(#{ANSWERS_TOO}))\s*$/i
      first_val = $1; second_val = $2; third_val = $3
      debug { "fv: #{first_val.inspect}; sv: #{second_val.inspect}; tv: #{third_val}" }
      if (first_val[/^\d+$/])
        filters[:id] = first_val
        ans = second_val
      else
        q_type = first_val
        whose = (MINE == second_val) ? owner : second_val
        ans = (third_val || ANSWERS_TOO == second_val) ? true : false
      end
      filters[:answers_too] = ans
      filters[:owner] = sanitize_filename(whose) if authorized.member?(whose)
      filters[:type] = (Q_TYPES - [ALL_QTYPE]).member?(q_type) ? q_type : "*"
      show_questions filters

    when /^#{CLOSE_CMD}(?:|\:)\s+([\d]+)/i
      filters[:id] = $1
      close_question filters

    else
      [UNKNOWN_CMD]

    end
  end

  protected

  def open_question filename, content
    unless File.exists?(file_dir(OPEN_QTYPE))
      Dir.chdir @db.working_dir
      Dir.mkdir OPEN_QTYPE
    end
    File.open(file_path(filename, OPEN_QTYPE), "w") do |f|
      f.puts "#{QUESTION_PREFIX} #{content[:question]} #{AUTHOR_PREFIX} #{content[:author]}"
    end
    @db.commit(filename, OPEN_QTYPE)
    incr
  end

  def append_answer_to_file filename, content
    return [UNKNOWN_QUESTION_ERROR] unless File.exists?(filename)
    File.open(filename, "a") do |f|
      f.puts "#{ANSWER_PREFIX} #{content[:answer]} #{RESPONDENT_PREFIX} #{content[:author]}"
    end
    @db.commit(*file_and_sub_dir(filename))
    
  end

  def file_and_sub_dir(fullpath)
    file_and_sub_dir_ary = [File.basename(fullpath)]

    case File.dirname(fullpath)
    when file_dir(OPEN_QTYPE)
      file_and_sub_dir_ary << OPEN_QTYPE

    when file_dir(CLOSE_QTYPE)
      file_and_sub_dir_ary << CLOSE_QTYPE

    else
      raise RuntimeError, "Unknown File Path: #{File.dirname(fullpath).inspect} vs. #{file_dir(OPEN_QTYPE)} "

    end
  end

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

  def id_and_description filename
    file_basename_without_extension(filename).sub(/#{OWNER_PREFIX}.*$/, "")
  end

  def file_basename_without_extension(filename)
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
      "#{SHOW_CMD}: <id>|#{SHOW_CMD}: <id> #{ANSWERS_TOO}|#{SHOW_CMD}: <q_type>|#{SHOW_CMD}: <q_type> <owner>|#{SHOW_CMD}: <q_type> #{ANSWERS_TOO}",
      "#{ANSWER_CMD}: <id> an answer is.",
      "#{CLOSE_CMD}: <id>",
      "\t<q_type>: #{Q_TYPES.join(" | ")}",
      "\t<owner>: #{MINE} | #{authorized.join(" | ")}"
    ]
  end

  def question_files filters={}
    filters = DEFAULT_OPEN_FILTERS.merge(filters)
    debug { "w/ filters: #{filters.inspect}" }
    Dir[file_path(filters[:id] + "#{OWNER_PREFIX}#{filters[:owner]}.#{FILE_SUFFIX}", filters[:type])]
  end

  def extract_questions filename, answers_too=false
    filter = match_question(answers_too)
    (File.open(filename).select &filter).collect do |question|
      question.chomp! if question.respond_to?(:chomp!)
    end
  end

  def match_question(answers_too=false)
    regex = QUESTION_PREFIX
    regex += "|#{ANSWER_PREFIX}" if answers_too
    lambda {|line| line =~ /^(?:#{regex})/ }
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
            debug { "send_im: #{add_html(line)}" }
            puts "send_im: #{line}" unless verbose?
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
    debug { "result: #{result.inspect}" }
  rescue Exception => e
    puts handle(e)
  end

  # should this be protected ?
  def process(message, screen_name)
    exit if exit?(message)
    if run_pre_cmd(message)
      line = verbose? ? "QUIET MODE: off" : "QUIET MODE: on"
      yield line if block_given?
      return
    end
    result = super(message, screen_name)
    # puts "result: #{result.inspect}"
    result.each do |lines|
      # puts "lines: #{lines.inspect}"
      if lines.is_a? Array
        lines.each do |line|
          line.to_s! if line.respond_to?(:to_s!)
          yield line if block_given?
        end
      else
        line = (lines.respond_to?(:to_s)) ? lines.to_s : lines
        yield line if block_given?
      end
    end
  end

  private

  attr_reader :pwd

  def run_pre_cmd(message)
    case message
    when *['Verbose','verbose']
      self.verbose = true
      true
    when  *['Quiet','quiet']
      self.verbose = false
      true
    else
      false
    end
  end

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