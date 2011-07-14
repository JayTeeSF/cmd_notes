#!/usr/bin/env ruby

require 'fileutils'
require 'rubygems'
require 'net/toc'
require ENV["HOME"] + "/bin/secure_settings.rb"

module DebugPrinter
  attr_accessor :verbose

  def verbose?
    verbose
  end

  def debug &block
    puts yield if verbose?
  end
end

module QStats
  OPEN_QSTATUS = "open"
  CLOSE_QSTATUS = "closed"
  ALL_QSTATUS = "all"
  Q_TYPES = [OPEN_QSTATUS, CLOSE_QSTATUS, ALL_QSTATUS]
end

module QnAEmbellishment
  QUESTION_PREFIX = "Hmm..."
  AUTHOR_PREFIX = "...wonders,"

  ANSWER_PREFIX = "How about:"
  RESPONDENT_PREFIX = "...says,"
end

class GitRepo
  DEFAULT_BASE_PATH = '/tmp' # you may want to move this ;-)
  ALL_FILES = ".".freeze

  attr_reader :base_path, :name, :working_dir, :index

  def initialize( _name, _base_path=nil )
    @base_path = _base_path || DEFAULT_BASE_PATH
    @name = _name
    @working_dir = "#{base_path}/#{name}"
    @index = "#{base_path}/#{name}/.git"
  end

  def init
    unless File.exists?(index)
      FileUtils.mkdir_p base_path
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

require 'sqlite3'
class DbRepo
  include DebugPrinter
  include QStats
  include QnAEmbellishment

  CREATE_QUERIES = {
    :authors => "CREATE TABLE authors(id INTEGER PRIMARY KEY, screenname varchar(255))",
    :questions => "CREATE TABLE questions(id INTEGER PRIMARY KEY, author_id integer, text varchar(255), status varchar(255))",
    :comments => "CREATE TABLE comments(id INTEGER PRIMARY KEY, question_id integer, author_id integer, text varchar(255))"
  }

  attr_reader :connection, :db_file, :config_file

  def find_all_questions_by(filters)
    get_comments = filters.delete(:answers_too) || false
    if author = filters.delete(:owner)
      filters[:author_id] = author_id(author)
    end
    filters[:status] = OPEN_QSTATUS unless filters[:status]
    filters.delete(:status) if '*' == filters[:status]

    _query = "SELECT id, text FROM questions" + where_clause(filters)
    debug {"query: #{_query}"}
    questions = {}
    connection.query(_query) do |result|
      id, text = result.next
      debug {"id: #{id.inspect}, text: #{text.inspect}"}
      questions[id] = {:text => text.dup} if text
    end
    return ["no questions"] if questions.empty?

    get_comments ? append_comments(questions) : questions.map do |q_id,v|
      "#{q_id} => #{QUESTION_PREFIX} #{v[:text]} #{AUTHOR_PREFIX} #{question_author(q_id)}"
    end
  end

  def append_comments(questions={})
    q_ids = questions.keys.dup
    q_ids.each do |q_id|
      comments = find_all_comments_by(q_id)
      questions[q_id][:comments] = comments unless comments.empty?
    end

    questions.map do |q_id,v|
      question_info = "#{q_id} => #{QUESTION_PREFIX} #{v[:text]} #{AUTHOR_PREFIX} #{question_author(q_id)}"
      v[:comments] ? question_info + "\n\t#{v[:comments].values.map{|h| "#{ANSWER_PREFIX} #{h[:text]} #{RESPONDENT_PREFIX} #{author(h[:author_id])}"}.join("\n\t")}" : question_info
    end
  end

  def find_all_comments_by(question_id)
    comments = {}
    _query = "SELECT id, text, author_id FROM comments where question_id = #{question_id}"
    connection.query(_query) do |result|
      id, text, author_id = result.next
      debug {"id: #{id.inspect}, text: #{text.inspect}"}
      comments[id] = {} if text || author_id
      comments[id][:text] = text.dup if text
      comments[id][:author_id] = author_id if author_id      
    end
    comments
  end



  # def find_question_by_id(id)
  #   _query = "SELECT text FROM questions where id = #{id}"
  #   connection.get_first_value(_query)
  # end

  def question_author(question_id)
    connection.get_first_value("SELECT screenname FROM authors, questions where authors.id = questions.author_id and questions.id = "+question_id.to_s)
  end

  def author(author_id)
    connection.get_first_value("SELECT screenname FROM authors where authors.id = "+author_id.to_s)
  end

  def author_id(author)
    connection.get_first_value("SELECT id FROM authors where screenname = '"+author+"'").to_s
  end

  def close(question_id)
    connection.execute "UPDATE questions set status = '#{CLOSE_QSTATUS}' where id = "+question_id
  end

  def answer(answer, author, question_id)
    connection.execute "INSERT INTO comments(text, author_id, question_id) VALUES('"+answer+"', "+author_id(author)+", "+question_id+")"
  end

  def store_question(question, author)
    debug {"storing question (#{question}) by #{author}"}
    unless 1 == connection.get_first_value("SELECT count(*) FROM authors where screenname = '"+author+"'")
      debug {"adding #{author.inspect} to the authors table"}
      connection.execute "INSERT INTO authors(screenname) VALUES('"+author+"')"
    end
    a_id = author_id(author)
    debug {"author_id: #{a_id.inspect}"}
    connection.execute "INSERT INTO questions(author_id, text) VALUES("+a_id+", '"+question+"')"
  end

  def initialize(options={})
    @verbose = !! options[:verbose]
    @config_file = ENV["HOME"] + "/config/database.yml"
    setup
  end

  def cleanup
    connection.close if connection
    # File.delete( db_file ) if File.exists? db_file
  end

  def setup
    connect_to_db
    startup
  end

  private

    def missing_tables?
      ! CREATE_QUERIES.keys.all? do |table|
        begin
          connection.execute "select count(*) from #{table}"
          true
        rescue SQLite3::SQLException
          false
        end
      end
    end

    def startup
      return unless missing_tables?

      CREATE_QUERIES.each_pair do |table, create_query|
        begin
          connection.execute "DROP TABLE #{table}"
        rescue SQLite3::SQLException => e
          puts "e: #{e.inspect}"
        end
        connection.execute create_query
      end
    end

    def where_clause(filters={})
      debug {"where w/ filters: #{filters.inspect}"}
      filters.empty? ? "" : " where #{filters.map{|k,v| "#{k} = '#{v}'" }.join(" and ")}"
    end

    def config
      require 'yaml'
      return {} unless File.exists?(config_file)
      YAML::load_file(config_file)
    end

    def connect_to_db
      @db_file = config["question_bot"]["database"]
      @connection = SQLite3::Database.new db_file
    end
end

module BotCommander
  extend self
  include DebugPrinter
  include QStats

  # BEGIN-BOGUS:
  OWNER_PREFIX = "_by_"
  FILE_SUFFIX = "qst"
  # END-BOGUS

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
  UNKNOWN_QUESTION_ERROR_PREFIX = "I know nothing about"
  NO_QUESTIONS_FOUND = "No Questions"

  CLOSED_OK = "closed."
  REGISTERED_OK = "hold that thought."
  ANSWERED_OK = "That's what you say!"

  attr_reader :repo
  def init(base_path=nil)
    @repo = DbRepo.new(:verbose => verbose)
    # @repo = GitRepo.new("question_bot_repo" base_path)
    # repo.init
    # @next_question_id = 1 + Dir[@db.working_dir + "/**/*.#{FILE_SUFFIX}"].count
  end

  # Filters:
  #   :id => ...
  #   :owner => ...
  #   :status => ...
  def show_questions filters={}
    debug {"got 'show_questions' filters: #{filters.inspect}"}
    questions = repo.find_all_questions_by(filters)
    questions.empty? ? [NO_QUESTIONS_FOUND] : questions

    # results = files.map do |filename|
    #   _id_and_descr = id_and_description filename
    #   debug { filters[:answers_too] ? "filters TOO" : "NO FILTERS" }
    #
    #   questions = extract_questions(filename, filters[:answers_too])
    #
    #   unless _id_and_descr || questions
    #     nil
    #   else
    #     [_id_and_descr + " => " + questions.first] +
    #     questions[1..-1].collect do |question|
    #       "\t => " + question
    #     end
    #   end
    # end.compact
    # return results.empty? ? [NO_QUESTIONS_FOUND] : results
  end

  def close_question filters={}
    debug {"got 'close_question' filters: #{filters.inspect}"}
    repo.close(filters[:id])

    [CLOSED_OK]
  end

  def register_question question, owner
    repo.store_question(question, owner)

    [REGISTERED_OK]
  end

  def answer_question answer, author, filters={}
    repo.answer(answer, author, question_id=filters[:id])
    [ANSWERED_OK]
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
      # should attempt to answer the question, if we know it already, else say: "I know nothing about #{question}"

    when /^(?:|#{ANSWER_CMD})(?:|\:\s+)\s*([\d]+)\s+(.+\.)\s*$/i
      filters[:id] = $1; answer = $2
      answer_question answer, owner, filters

    when /^(?:|#{SHOW_CMD})(?:|\:\s+)\s*([\d]+|(?:#{Q_TYPES.join("|")})+(?:|\s+([\w]+)))(?:|\s+(#{ANSWERS_TOO}))\s*$/i
      first_val = $1; second_val = $2; third_val = $3
      debug { "fv: #{first_val.inspect}; sv: #{second_val.inspect}; tv: #{third_val}" }
      if (first_val[/^\d+$/])
        filters[:id] = first_val
      else
        q_status = first_val
        whose = (MINE == second_val) ? owner : second_val
      end
      ans = (third_val || ANSWERS_TOO == second_val) ? true : false
      filters[:answers_too] = ans
      filters[:owner] = sanitize_filename(whose) if authorized.member?(whose)
      filters[:status] = (Q_TYPES - [ALL_QSTATUS]).member?(q_status) ? q_status : "*"
      show_questions filters

    when /^#{CLOSE_CMD}(?:|\:)\s+([\d]+)/i
      filters[:id] = $1
      close_question filters

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

  # def id_and_description filename
  #   file_basename_without_extension(filename).sub(/#{OWNER_PREFIX}.*$/, "")
  # end

  def replace_special_chars(str)
    str.gsub(/[^0-9A-Za-z.\-]/, SPECIAL_CHAR_REPLACEMENT)
  end
  
  def remove_invalid_chars(str)
    str.gsub(/^.*(\\|\/)/, '')
  end

  # attr_reader :next_question_id

  def cmd_info
    [
      HELP_CMD,
      "#{REGISTER_CMD}: some question?",
      "#{SHOW_CMD}: <id>|#{SHOW_CMD}: <id> #{ANSWERS_TOO}|#{SHOW_CMD}: <q_status>|#{SHOW_CMD}: <q_status> <owner>|#{SHOW_CMD}: <q_status> #{ANSWERS_TOO}",
      "#{ANSWER_CMD}: <id> an answer is.",
      "#{CLOSE_CMD}: <id>",
      "\t<q_status>: #{Q_TYPES.join(" | ")}",
      "\t<owner>: #{MINE} | #{authorized.join(" | ")}"
    ]
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
  attr_accessor :one_time

  def one_time?
    !! one_time
  end

  def initialize(options={})
    @user = options[:user] || USER
    @pwd = options[:pwd] || PWD
    @authorized = options[:authorized] || AUTHORIZED
    @verbose = options[:verbose]
    @one_time = options[:one_time]
    init(options[:base_path])
  end

  def test(buddy=nil, message=nil)
    buddy ||= prompt BUDDY_PROMPT
    if authorized.member? buddy
      result = nil
      begin
        message = one_time? ? strip_html( message ) : strip_html( prompt(MESSAGE_PROMPT) )
        result = process(message, buddy) do |line|
          line.tap do |msg|
            if verbose?
              msg = add_html(msg)
              debug { "send_im: #{add_html(msg)}" }
            else
              puts "send_im: #{msg}" unless one_time?
            end
            puts unless one_time?
          end
        end
      rescue Exception => e
        handle(e, message).tap &print_msg
      end until one_time?
      result
    else
      IGNORE_MESSAGE.tap &print_msg
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
      return yield line if block_given?
    end
    result = super(message, screen_name)
    # puts "result: #{result.inspect}"
    result.each do |lines|
      # puts "lines: #{lines.inspect}"
      if lines.is_a? Array
        lines.collect do |line|
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

  def print_msg
    lambda { |msg|
      puts msg unless one_time?
      puts unless one_time?
    }
  end

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
    "#{e.class}: #{e.inspect} - #{e.backtrace}"
  end

  def exit?(message)
    QUIT_CMDS.member? message
  end

end

module CmdLineInterface
  extend self

  def usage
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

  def flush_input
    begin
      ARGV.shift
    end until ARGV.empty?
  end

  DEBUG_OPTION = 'debug'
  TEST_OPTION = 'test'
  HELP_OPTION = '--help'
  UNKNOWN_OPTION = 'Unknown option...'

  def run
    case ARGV[0]
    when nil
      Bot.new.start
    when DEBUG_OPTION
      flush_input
      Bot.new(:verbose => true).test
    when TEST_OPTION
      flush_input
      Bot.new.test
    when HELP_OPTION
      usage
    else
      puts UNKNOWN_OPTION
      usage
    end
  end
end

CmdLineInterface.run if $0 =~ /question_bot.rb/
