require 'rubyfit'
require 'awesome_print'

RSpec.configure do |config|
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end

class TestCallbacks
  attr_reader :file_id, :lap, :records, :events, :session

  def initialize
    @file_id = nil
    @lap = nil
    @records = []
    @events = []
    @session = nil
  end

  def print_msg(msg)
  end

  def print_error_msg(msg)
  end

  def on_file_id(msg)
    @file_id = msg
  end

  def on_activity(msg)
  end

  def on_lap(msg)
    @lap = msg
  end

  def on_session(msg)
    @session = msg
  end

  def on_record(msg)
    @records << msg
  end

  def on_event(msg)
    @events << msg
  end

  def on_device_info(msg)
  end

  def on_user_profile(msg)
  end

  def on_weight_scale_info(msg)
  end
end
