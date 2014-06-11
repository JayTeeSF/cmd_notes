require "#{File.dirname(ARGV[0])}/question_bot.rb"

describe "QuestionBot" do
  before (:all) do
    @debug = false
    @base_path = '/tmp/question_bot_repo_test_dir'

    @buddy = Bot.authorized_aim_contacts.first
    set_msg ""

    @options = {:one_time => true, :base_path => @base_path }
  end

  def answer1; "code-reading."; end
  def answer2; "code-conceptualizing."; end

  def question1; "code-curiosity?"; end
  def question2; "foo?"; end
  def question3; "bar?"; end

  def got
    @action.call
  end

  context "Given a fresh DB" do
    before(:each) do
      flush_db
      @bot = Bot.new(@options)
      @action = lambda {
        debug { "buddy: #{@buddy.inspect}, msg: #{@message}" }
        @bot.test(@buddy, @message).tap do |out|
          debug { "out: #{out.inspect}" }
        end
      }
    end


    describe "#register" do

      context "with no questions" do
        it "should register a question" do
          # register_first_question
          register_question question1
        end
      end

      context "with a question" do
        before(:each) do
          register_question question1
        end
        it "should register a question" do
          register_question question2
        end

        it "should register multiple question(s)" do
          register_question question2
          register_question question3
        end
      end

    end


    describe "#show" do
      context "by id" do
        context "with no questions" do
          it "should gracefully handle request" do
            show_question_when_no_questions
          end
        end

        context "with multiple questions" do
          before :each do
            #register_first_question
            register_question question1
            register_question question2
            register_question question3
          end

          it "should show each question" do
            show_a_question(1)
            show_a_question(2)
            show_a_question(3)
          end

          context "with no answers" do
            it "should show the question(s) but no answers" do
              show_all_question_and_their_answers_when_no_answers([question1, question2, question3])
            end
          end

          context "with an answer" do
            before(:each) do
              answer_open_question(1, answer1)
            end
            it "should return all answers" do
              show_all_questions_and_their_answers({question1 => [answer1], question2 => [], question3 => []})
            end

            it "should return all answers when two questions are answered" do
              answer_open_question(2, answer1)
              show_all_questions_and_their_answers({question1 => [answer1], question2 => [answer1], question3 => []})
            end

            it "should return all answers when all questions are answered" do
              answer_open_question(2, answer1)
              answer_open_question(3, answer2)
              show_all_questions_and_their_answers({question1 => [answer1], question2 => [answer1], question3 => [answer2]})
            end
          end

        end


        context "with a question" do
          before :each do
            #register_first_question
            register_question question1
          end
          it "should show the question" do
            show_a_question(1)
          end

          context "with no answers" do
            it "should show the question and no answers" do
              show_a_question_and_its_answers_when_no_answers(1)
            end
          end

          context "with an answer" do
            before :each do
              answer_open_question(1, answer1)
            end

            context "typ-o'd command" do
              it "should gracefully handle request" do
                show_a_question_and_its_answers_when_typo(1, typ_o = 'and')
              end
            end

            it "should show a question and its answer(s)" do
              show_a_question_and_its_answers(1, [answer1])
            end

            it "should return all answers" do
              show_all_questions_and_their_answers({1 => [answer1]})
            end

            context "with multiple answers" do
              before :each do
                answer_open_question(1, answer2)
              end

              it "should show a question and its answer(s)" do
                show_a_question_and_its_answers(1, [answer1, answer2])
              end

              it "should return all answers" do
                show_all_questions_and_their_answers({1 => [answer1, answer2]})
              end

            end

          end
        end
      end
    end

    describe "#close" do

      context "with no questions" do
        it "should gracefully handle request" do
          close_question_when_no_open_questions
        end
      end

      context "with a closed question" do
        before :each do
          # register_first_question
          register_question question1
          close_question(1)
        end

        it "should gracefully handle request" do
          close_question_when_no_open_questions
        end
      end

      context "with an open question" do
        before :each do
          #register_first_question
          register_question question1
        end

        it "should close an open question" do
          close_question(1)
        end
      end

    end

    describe "#answer" do
      context "with no questions" do
        it "should gracefully handle request" do
          answer_question_when_no_open_questions
        end
      end

      context "with an open question" do
        before :each do
          #register_first_question
          register_question question1
        end

        it "should answer a question" do
          answer_open_question(1, answer1)
          answer_open_question(1, answer2)
        end
      end

    end

  end

  # HELPERS
  def flush_db
    if File.exists?(@base_path)
      puts "removing db at #{@base_path.inspect}"
      %x{rm -rf #{@base_path}}
    else
      puts "no db at #{@base_path.inspect}"
    end
  end

  def debug
    puts yield if @debug && block_given?
  end

  def set_msg(val)
    @message = val
  end

  def show_a_question(id, answer_count=0)
    set_msg id.to_s
    got.tap do |_got|
      _got.flatten.count.should == 1 + answer_count
      (_got.flatten.first =~ /#{BotCommander::QUESTION_PREFIX}/).should be_true
    end
  end

  def show_all_questions_and_their_answers(q_n_a={})
    questions = q_n_a.keys.flatten
    answers = q_n_a.values.flatten

    set_msg "all ans"
    _got = got

    (_got.flatten.first =~ /#{BotCommander::QUESTION_PREFIX}/).should be_true
    question_responses = _got.flatten.select {|line| line =~ /#{BotCommander::QUESTION_PREFIX}/}
    question_responses.count.should be( questions.count), "question_responses: #{question_responses.inspect}"
    answer_responses = _got.flatten.select {|line| line =~ /#{BotCommander::ANSWER_PREFIX}/}
    answer_responses.count.should be(answers.count), "answer_responses: #{answer_responses.inspect}"

    # outer-loop questions -- how to match the order ?!
    # answers.each_with_index do |answer, index|
    #   (_got.flatten[1 + index] =~ /#{BotCommander::ANSWER_PREFIX}.*#{answer}/).should be_true
    # end
  end

  def show_all_question_and_their_answers_when_no_answers(questions=[])
    show_all_questions_and_their_answers(questions.inject({}){|memo,q| memo[q] = []; memo})
  end

  def show_a_question_and_its_answers(id, answers=[])
    _got = show_a_question("#{id} ans", answers.count)

    answers.each_with_index do |answer, index|
      (_got.flatten[1 + index] =~ /#{BotCommander::ANSWER_PREFIX}.*#{answer}/).should be_true
    end
  end

  def show_a_question_and_its_answers_when_no_answers(id)
    show_a_question("#{id} ans")
  end

  def show_a_question_and_its_answers_when_typo(id, typo)
    set_msg "#{id} #{typo}"
    got.tap do |_got|
      _got.flatten.count.should == 1
      (_got.flatten.first =~ /#{BotCommander::UNKNOWN_CMD}/ ).should be_true
    end
  end

  def close_question(id, verify=true)
    set_msg "close #{id}"
    got.tap do |_got|
      _got.should == [BotCommander::CLOSED_OK] if verify
    end
  end

  def close_question_when_no_open_questions
    close_question(1, false).should == [BotCommander::UNKNOWN_QUESTION_ERROR]
  end

  def show_question_when_no_questions
    set_msg "1"
    got.should == [BotCommander::NO_QUESTIONS_FOUND]
  end

  def register_question question
    set_msg question
    got.should == [BotCommander::REGISTERED_OK]
  end

  #def register_first_question
  #  #set_msg question1
  #  #got.should == [BotCommander::REGISTERED_OK]
  #end

  def answer_question_when_no_open_questions
    set_msg "1 #{answer1}"
    got.should == [BotCommander::UNKNOWN_QUESTION_ERROR]
  end

  def answer_open_question(id, answer)
    set_msg "#{id} #{answer}"
    got.any?{|msg| msg =~ /commiting/}.should be_true
  end

end
