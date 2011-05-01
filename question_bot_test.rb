require 'test/unit'
require 'question_bot.rb'

class QuestionBotTest < Test::Unit::TestCase

  def setup
    @bot = Bot.new
    @buddy = Bot::AUTHORIZED.first
    base_path = '/tmp/question_bot_repo_test_dir'
    %x{rm -rf #{base_path}} if File.exists?(base_path)
    @options = {:one_time => true, :base_path => base_path }
    @message = ""
    @action = lambda { @bot.test(@buddy, @message, @options) }
  end

  def test_register_question
    @message = "code-curiosity?"
    got = @action.call
    assert( got == [BotCommander::REGISTERED_OK] )
  end

  def test_show_question
    # show q: when no q
    @message = "1"
    got = @action.call
    assert( got == [BotCommander::NO_QUESTIONS_FOUND] )

    # register:
    @message = "code-curiosity?"
    got = @action.call
    assert( got == [BotCommander::REGISTERED_OK] )

    # show q
    @message = "1"
    got = @action.call
    assert( got.flatten.count == 1 )
    assert( got.flatten.first =~ /#{BotCommander::QUESTION_PREFIX}/ )
  end

  def test_show_question_and_answer
    # register:
    @message = "code-curiosity?"
    got = @action.call
    assert( got == [BotCommander::REGISTERED_OK] )

    # show q&a: when no ans, just see q
    @message = "1 ans"
    got = @action.call
    assert( got.flatten.count == 1 )
    assert( got.flatten.first =~ /#{BotCommander::QUESTION_PREFIX}/ )

    # ans:
    @message = "1 code-reading."
    got = @action.call
    assert( got.any?{|msg| msg =~ /commiting/} )

    # show q&a:
    @message = "1 ans"
    got = @action.call
    assert( got.flatten.count == 2 )
    assert( got.flatten.first =~ /#{BotCommander::QUESTION_PREFIX}/ )
    assert( got.flatten.last =~ /#{BotCommander::ANSWER_PREFIX}/ )
  end

  def test_answer_question
    # ans missing-q:
    @message = "1 code-reading."
    got = @action.call
    assert( got == [BotCommander::UNKNOWN_QUESTION_ERROR] )

    # register:
    @message = "code-curiosity?"
    got = @action.call
    assert( got == [BotCommander::REGISTERED_OK] )

    # ans:
    @message = "1 code-reading."
    got = @action.call
    assert( got.any?{|msg| msg =~ /commiting/} )

    #message: 1 code-reading.
    #send_im: [master e217aff] commiting 1_by_jayteework.qst
    #send_im:  1 files changed, 1 insertions(+), 0 deletions(-)
    #
    #message: 1 code-conceptualizing.
    #send_im: [master f91b139] commiting 1_by_jayteework.qst
    #send_im:  1 files changed, 1 insertions(+), 0 deletions(-)
    #
    #message: all and
    #send_im: 1 => Hmm... code-curiosity? ...wonders, jayteework
    #
    #message: all ans
    #send_im: 1 => Hmm... code-curiosity? ...wonders, jayteework
    #send_im:  => One Answer is: code-reading. ...says, jayteework
    #send_im:  => One Answer is: codee-conceptualizing. ...says, jayteework
  end
end
