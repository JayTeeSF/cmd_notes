  class AutomatedActionRunner
  
  # thanks to DHH's gist: https://github.com/rails/rails/issues/18409
  
      class StatusObject
    def initialize(is_valid, error_obj)
      @is_valid = !! is_valid
      @error_obj = error_obj
    end

    def valid?
      @is_valid
    end
    def error
      @error_obj
    end
  end

  def self.help
    puts <<-EOH
      Instead tying-up the frontend of your production site with:
        `curl http://your_production_site.com/some_controller/some_action/1234`
        `curl http://your_production_site.com/some_controller/some_action/4567`
      Try:
        `rails r 'AutomatedActionRunner.run(SomeController, "some_action", [{id: "1234"}, {id: "4567"}])'`
    EOH
  end

  def self.common_env
    {"rack.input"  => "", "SCRIPT_NAME" => "", "HTTP_HOST" => "localhost:3000" }
  end
  REQUEST_ENV = common_env.freeze
  
  def self.run(controller, controller_action, params_ary=[], user_obj=nil)
    success_objects = []
    error_objects = []
    autorunner = new(controller, controller_action, user_obj)
    Rails.logger.warn %Q|[AutomatedAction Kickoff]: Preheating cache for #{params_ary.size} #{autorunner.controller.name}##{controller_action} pages.|

    params_ary.each do |params_hash|
      status = autorunner.run(params_hash)
      if status.valid?
        success_objects << params_hash
      else
        error_objects << status.error
      end
    end

    return process_results(success_objects, error_objects, user_obj.try(:id), autorunner.controller.name, controller_action)
  end

  def self.process_results(success_objects=[], error_objects=[], user_id, controller_name, controller_action)
    message = %Q|AutomatedAction Summary|
    backtrace = (error_objects.first.try(:backtrace)||[]).join("\n\t").inspect
    num_errors = error_objects.size
    num_successes = success_objects.size

    log_message = %Q|[#{message}]: Generated #{num_successes} #{controller_name}##{controller_action}, pages; Failed #{num_errors} times; 1st Fail: #{backtrace}|
    Rails.logger.warn log_message

    # all the local-variables above, are because I typically call Sentry or something with extra parameters!
  end

  attr_reader :controller
  def initialize(controller, controller_action, user_obj)
    @controller = controller
    @controller = controller.constantize unless controller.respond_to?(:name)

    @controller_action = controller_action
    @env_obj = REQUEST_ENV
    @user_obj = user_obj
  end

  def run(params_hash)
    Rails.logger.warn %Q|[AutomatedAction]: #{@controller.name}##{@controller_action}(#{params_hash.inspect})|

    setup_for_autorun
    @controller_instance.autorun(@controller_action, params_hash)
  end


  private

  def setup_for_autorun
    @controller_instance = @controller.new
    @controller_instance.request = ActionDispatch::Request.new(@env_obj.dup)
    @controller_instance.response = ActionDispatch::Response.new
    @controller_instance.define_singleton_method(:current_user, -> { @user_obj })

    extend_with_autorun unless @controller_instance.respond_to?(:autorun)
  end
  
  def extend_with_autorun
    def @controller_instance.autorun(action_name, action_params, action_env, current_user_value=nil)
      self.params = action_params # suppress strong parameters exception
      self.request = ActionDispatch::Request.new(action_env)
      self.response = ActionDispatch::Response.new
      define_singleton_method(:current_user, -> { current_user_value })

      send(action_name) # do it
      return StatusObject.new(true, nil)
    rescue Exception => e
      return StatusObject.new(false, e)
    end
  end
end
