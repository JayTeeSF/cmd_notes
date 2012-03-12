require 'spec_helper'

describe UnlinkableNestedAttributes do
  subject do
    Class.new
    end

    context "without mix-in" do
      it { should_not respond_to(:nest_with_unlink_for) }
    end

    context "with mix-in" do
      context "without support for REQUIRED_METHODS" do
        it "should raise" do
          lambda { subject.send(:include, UnlinkableNestedAttributes) }.should raise_error(ArgumentError)
        end
      end
      context "with support for REQUIRED_METHODS" do
        before(:each) do
          subject.class_eval do
            def self._tmp_eigenclass
              class << self; self; end
            end
          end
          UnlinkableNestedAttributes::REQUIRED_CLASS_METHODS.each do |method_name|
            subject._tmp_eigenclass.send(:define_method, method_name) {}
          end
          UnlinkableNestedAttributes::REQUIRED_INSTANCE_METHODS.each do |method_name|
            subject.send(:define_method, method_name) {}
          end
          subject.send(:include, UnlinkableNestedAttributes)
        end

        describe ".nest_with_unlink_for" do
          #nest_with_unlink_for :main_image, :unless => lambda { |attrs| attrs['name'].blank? }
          let(:attr_name_sym) { :some_image }
          let(:reject_method_name_sym) { "#{UnlinkableNestedAttributes::REJECT_METHOD_PREFIX}#{attr_name_sym}#{UnlinkableNestedAttributes::REJECT_METHOD_POSTFIX}".to_sym }
          let(:unlink_method_name_sym) { "#{UnlinkableNestedAttributes::UNLINK_METHOD_PREFIX}#{attr_name_sym}".to_sym }

          it { should respond_to(:nest_with_unlink_for) }

          context "without a block" do
            before :each do
              subject.should_receive(:accepts_nested_attributes_for).with(attr_name_sym, :reject_if => reject_method_name_sym)
            end
            it "should define methods and run '.accepts_nested_attributes_for'" do
              instance = subject.new
              instance.should_not respond_to(unlink_method_name_sym)
              instance.should_not respond_to(reject_method_name_sym)

              subject.nest_with_unlink_for attr_name_sym
              instance = subject.new
              instance.should respond_to(reject_method_name_sym)
              instance.should respond_to(unlink_method_name_sym)
            end
          end

          context "with association-class specified" do
            before :each do
              @association_class = mock().tap do |mock_class|
                mock_class.should_receive(:new).and_return(mock_class)
                mock_class.should_receive(:attr_reader).with(UnlinkableNestedAttributes::ClassMethods::InternalMethods.unlink_accessor)
              end
              subject.should_receive(:accepts_nested_attributes_for).with(attr_name_sym, :reject_if => reject_method_name_sym)
            end
            it "should .nest_with_unlink_for multiple attribute(s)" do
              instance = subject.new
              instance.should_not respond_to(unlink_method_name_sym)
              instance.should_not respond_to(reject_method_name_sym)

              subject.nest_with_unlink_for attr_name_sym, :on => @association_class
              instance = subject.new
              instance.should respond_to(reject_method_name_sym)
              instance.should respond_to(unlink_method_name_sym)

              # shouldn't re-create the _unlink method
              @association_class.should_receive(:respond_to?).with(UnlinkableNestedAttributes::ClassMethods::InternalMethods.unlink_accessor).and_return(true)
              @association_class.should_receive(:new).and_return(@association_class)
              subject.should_receive(:accepts_nested_attributes_for)
              subject.nest_with_unlink_for :other_attr, :on => @association_class
            end
          end

          context "with options for accepts_nested_attributes_for" do
            let(:options) do
              { :an_option => true, :another_option => false }
            end
            before :each do
              subject.should_receive(:accepts_nested_attributes_for).with(attr_name_sym, {:reject_if => reject_method_name_sym}.merge(options))
            end
            it "should .nest_with_unlink_for some attribute" do
              instance = subject.new
              instance.should_not respond_to(unlink_method_name_sym)
              instance.should_not respond_to(reject_method_name_sym)

              subject.nest_with_unlink_for attr_name_sym, options
              instance = subject.new
              instance.should respond_to(reject_method_name_sym)
              instance.should respond_to(unlink_method_name_sym)
            end
          end

          context "with a block" do
            let(:attrs) { {UnlinkableNestedAttributes::UNLINK_ATTR => UnlinkableNestedAttributes::UNLINK_ATTR_TRIGGER_VALUE, :attr2 => false} }
            before :each do
              @trigger = mock()
              @trigger.should_receive(:handle).with(attrs)
              @unless_block = lambda {|attrs| @trigger.handle(attrs) }
            end
            before :each do
              subject.should_receive(:accepts_nested_attributes_for).with(attr_name_sym, :reject_if => reject_method_name_sym)
            end
            it "should .nest_with_unlink_for some attribute" do
              instance = subject.new
              instance.should_not respond_to(unlink_method_name_sym)
              instance.should_not respond_to(reject_method_name_sym)

              subject.nest_with_unlink_for attr_name_sym, :unless => @unless_block
              instance = subject.new
              instance.should respond_to(reject_method_name_sym)
              instance.should respond_to(unlink_method_name_sym)

              instance.should_receive(:update_attributes).and_return(true)
              instance.send(reject_method_name_sym, attrs)
            end
          end
        end
      end
    end

  end
