require 'test/unit'
require 'question_bot.rb'

class QuestionBotTest < Test::Unit::TestCase
  # SETUP
  def setup
    @debug = false
    base_path = '/tmp/question_bot_repo_test_dir'
    %x{rm -rf #{base_path}} if File.exists?(base_path)

    @options = {:one_time => true, :base_path => base_path }
    @bot = Bot.new(@options)

    set_msg ""
    @buddy = Bot::AUTHORIZED.first
    @action = lambda {
      @bot.test(@buddy, @message).tap do |out|
        puts "out: #{out.inspect}" if @debug
      end
    }
  end

  def got
    @action.call
  end

  def set_msg(val)
    @message = val
  end

  def answer1; "code-reading."; end
  def answer2; "code-conceptualizing."; end

  def question1; "code-curiosity?"; end
  def question2; "foo?"; end
  def question3; "bar?"; end

  # TESTS (proper)
  def test_register_question
    register_first_question
  end

  def test_show_question
    show_question_when_none
    register_first_question
    show_a_question(1)
  end

  def test_show_question_and_answer
    register_first_question
    show_a_question_and_its_answers_when_no_answers(1)
    answer_open_question(1, answer1)
    show_a_question_and_its_answers_when_typo(1, typ_o = 'and')
    show_a_question_and_its_answers(1, [answer1])
    answer_open_question(1, answer2)
    show_a_question_and_its_answers(1, [answer1, answer2])
  end

  def test_close_question
    close_question_when_none
    register_first_question
  end

  def test_answer_question
    answer_question_when_none
    register_first_question
    answer_open_question(1, answer1)
    answer_open_question(1, answer2)
  end

  def test_all_answers
    @pending
    #message: all ans
    #send_im: 1 => Hmm... code-curiosity? ...wonders, jayteework
    #send_im:  => One Answer is: code-reading. ...says, jayteework
    #send_im:  => One Answer is: codee-conceptualizing. ...says, jayteework
  end

  # HELPERS
  def show_a_question(id, answer_count=0)
    set_msg id.to_s
    got.tap do |_got|
      assert( _got.flatten.count == 1 + answer_count )
      assert( _got.flatten.first =~ /#{BotCommander::QUESTION_PREFIX}/ )
    end
  end

  def show_a_question_and_its_answers(id, answers=[])
    _got = show_a_question("#{id} ans", answers.count)
    answers.each_with_index do |answer, index|
      assert( _got.flatten[1 + index] =~ /#{BotCommander::ANSWER_PREFIX}.*#{answer}/ )
    end
  end

  def show_a_question_and_its_answers_when_no_answers(id)
    show_a_question("#{id} ans")
  end

  def show_a_question_and_its_answers_when_typo(id, typo)
    set_msg "#{id} #{typo}"
    got.tap do |_got|
      assert( _got.flatten.count == 1 )
      assert( _got.flatten.first =~ /#{BotCommander::UNKNOWN_CMD}/ )
    end
  end

  def close_question_when_none
    set_msg "close 1"
    assert( got == [BotCommander::UNKNOWN_QUESTION_ERROR] )
  end

  def show_question_when_none
    set_msg "1"
    assert( got == [BotCommander::NO_QUESTIONS_FOUND] )
  end

  def register_first_question
    set_msg question1
    assert( got == [BotCommander::REGISTERED_OK] )
  end

  def answer_question_when_none
    set_msg "1 #{answer1}"
    assert( got == [BotCommander::UNKNOWN_QUESTION_ERROR] )
  end

  def answer_open_question(id, answer)
    set_msg "#{id} #{answer}"
    assert( got.any?{|msg| msg =~ /commiting/} )
  end

end
