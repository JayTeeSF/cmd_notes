module Base
  class Widget
    include SilentException
    def initialize(*args)
      silence_exception Exception, :on => :render
    end
  end
end

module SilentException
  attr_reader :silent_exceptions_for

  # silence_exception Exception, :on => :method1, :instead => lambda {|e| Airbrake.notify(e) }
  # silence_exception [Exception1, Exception2], :on => [:method1, :method2]
  def silence_exception exception_or_exceptions, options={}
    instead = options[:instead] || lambda {|e| Airbrake.notify(e) }

    extend SilentException::WrapMethods
    array_of(options[:on]).each do |method_name|
      add_silent_exceptions_for(method_name, array_of(exception_or_exceptions))
      wrap(method_name, instead)
    end
  end

  def add_silent_exceptions_for(method_name, exceptions)
    @silent_exceptions_for ||= {}
    @silent_exceptions_for[method_name] ||= []
    @silent_exceptions_for[method_name] |= exceptions
  end
  private :add_silent_exceptions_for

  def array_of(one_or_many_items)
    if one_or_many_items.respond_to?(:each)
      one_or_many_items
    else
      [one_or_many_items]
    end
  end
  private :array_of

  module WrapMethods
    METHOD_PREFIX = 'silent_exception_response_for_'
    def _eigenclass
      class << self; self; end
    end

    def wrap(method_name, instead)
      _eigenclass.class_eval do
        def silent_exception_response_for(method_name)
          silent_method = "#{METHOD_PREFIX}#{method_name}"
          respond_to?(silent_method) ? send(silent_method) : ''
        end

        def silent_exception_for?(method_name, exception_class)
          silent_exceptions_for[method_name] &&
          silent_exceptions_for[method_name].include?(exception_class)
        end

        define_method(method_name) do |*args|
          begin
            super
          rescue Exception => e
            raise e unless silent_exception_for?(method_name, e.class)
            instead.call(e)
            silent_exception_response_for(method_name)
          end
        end
      end
    end
  end
end


require 'spec_helper'

describe SilentException do
  let(:class_under_test) do
    Class.new
  end

  before do
    class_under_test.class_eval do
      include SilentException
      def initialize(*args)
        silence_exception ArgumentError, :on => :custom_render
        silence_exception RuntimeError, :on => :default_render
        silence_exception [ArgumentError, RuntimeError], :on => :multi_exception
      end

      define_method("#{SilentException::WrapMethods::METHOD_PREFIX}custom_render") do
        "#{SilentException::WrapMethods::METHOD_PREFIX}custom_render"
      end

      def default_render
        exception_raiser RuntimeError
      end

      def custom_render
        exception_raiser ArgumentError
      end

      def multi_exception(which_exception_to_raise=ArgumentError)
        exception_raiser which_exception_to_raise
      end

      def exception_raiser(which_exception_to_raise=ArgumentError)
        raise which_exception_to_raise, "got bar's exception"
      end
    end
  end

  subject { class_under_test.new }

  it "should return the default silent response" do
    Airbrake.should_receive(:notify)
    subject.default_render.should be_blank
  end

  it "should return the default silent response for multiple exceptions" do
    Airbrake.should_receive(:notify).twice
    subject.multi_exception(ArgumentError).should be_blank
    subject.multi_exception(RuntimeError).should be_blank
  end

  it "should raise on an unspecified exception" do
    Airbrake.should_not_receive(:notify)
    lambda { subject.multi_exception(Exception)}.should raise_error(Exception)
  end

  it "should return the default silent response" do
    Airbrake.should_receive(:notify)
    subject.default_render.should be_blank
  end

  it "should return the custom silent response" do
    Airbrake.should_receive(:notify)
    subject.custom_render.should == "#{SilentException::WrapMethods::METHOD_PREFIX}custom_render"
  end
end