  class AutomatedActionRunner
  
  # thanks to DHH's gist: https://github.com/rails/rails/issues/18409
  
  def self.common_env
    {"rack.input"  => "", "SCRIPT_NAME" => "", "HTTP_HOST" => "localhost:3000" }
  end
  REQUEST_ENV = common_env.freeze
  
  def self.run(ctrl, ctrl_action, params_ary=[], user_obj=nil)
    ctrl = ctrl.constantize unless ctrl.respond_to?(:name)
    Rails.logger.warn %Q|[AutomatedAction] #{ctrl}##{ctrl_action} x #{params_ary.size}...|
    params_ary.each do |params_hash|
      Rails.logger.warn %Q|\t[AutomatedAction]: #{ctrl_action}(#{params_hash.inspect})|
      ctrl.new.tap { |ctrl_instance|
        def ctrl_instance.autorun(action_name, action_params, action_env, current_user_value=nil)
          self.params = action_params # suppress strong parameters exception
          self.request = ActionDispatch::Request.new(action_env)
          self.response = ActionDispatch::Response.new
          define_singleton_method(:current_user, -> { current_user_value })

          send(action_name) # do it
        end
      }.autorun(ctrl_action, params_hash, REQUEST_ENV.dup, user_obj)
    end
  end
end
