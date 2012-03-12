module UnlinkableNestedAttributes
  UNLINK_ATTR = '_unlink'
  REJECT_METHOD_PREFIX = 'skip_invalid_or_unlink_'
  REJECT_METHOD_POSTFIX = '?'
  UNLINK_METHOD_PREFIX = 'unlink_'
  UNLINK_ATTR_TRIGGER_VALUE = '1' # check_box returns 1 when its checked
  REQUIRED_CLASS_METHODS = [:accepts_nested_attributes_for]
  REQUIRED_INSTANCE_METHODS = [:update_attributes]

  def self.included(base)
    ensure_support_for(base)
    base.extend ClassMethods
  end

  def self.ensure_support_for(base)
    REQUIRED_CLASS_METHODS.each do |method_name|
      unless base.respond_to?(method_name)
        raise ArgumentError, "#{base} can't include #{self} because it does not respond_to #{method_name}"
      end
    end
    instance_obj = base.new
    REQUIRED_INSTANCE_METHODS.each do |method_name|
      unless instance_obj.respond_to?(method_name)
        raise ArgumentError, "#{base} can't include #{self} because its instances do not respond_to #{method_name}"
      end
    end
  end

  module ClassMethods
    def nest_with_unlink_for(attr_name_sym, options={})
      unless_block = options.delete(:unless)
      if base_class = options.delete(:on)
        unless base_class.new.respond_to?(InternalMethods.unlink_accessor)
          base_class.send(:attr_reader, InternalMethods.unlink_accessor)
        end
      end

      define_method InternalMethods.unlink_method_name(attr_name_sym) do
        self.update_attributes(attr_name_sym => nil)
      end

      define_method InternalMethods.reject_method_name(attr_name_sym) do |attrs|
        (UNLINK_ATTR_TRIGGER_VALUE == attrs.delete(UNLINK_ATTR)) && send(InternalMethods.unlink_method_name(attr_name_sym)) && unless_block ? unless_block.call(attrs) : true
      end

      nested_attr_options = {:reject_if => InternalMethods.reject_method_name(attr_name_sym).to_sym}.merge(options)
      accepts_nested_attributes_for attr_name_sym, nested_attr_options
    end

    module InternalMethods
      extend self
      def reject_method_name(attr_name)
        "#{REJECT_METHOD_PREFIX}#{attr_name}#{REJECT_METHOD_POSTFIX}"
      end

      def unlink_method_name(attr_name)
        "#{UNLINK_METHOD_PREFIX}#{attr_name}"
      end

      def unlink_accessor
        UNLINK_ATTR.to_sym
      end
    end
  end
end
