require "rubyfit/message_writer"

class RubyFit::Writer
  PRODUCT_ID = 65534 # Garmin Connect

  def write(stream, opts = {})
    raise "Can't start write mode from #{@state}" if @state
    @state = :write
    @local_nums = {}
    @last_local_num = -1

    @stream = stream

    %i(start_time duration course_point_count track_point_count name
       total_distance time_created start_x start_y end_x end_y).each do |key|
      raise ArgumentError.new("Missing required option #{key}") unless opts[key]
    end

    start_time = opts[:start_time].to_i
    duration = opts[:duration].to_i
    
    @data_crc = 0

    data_size = calculate_data_size(opts[:course_point_count], opts[:track_point_count])
    write_data(RubyFit::MessageWriter.file_header(data_size))

    write_message(:file_id, {
      time_created: opts[:time_created],
      type: 6, # Course file
      manufacturer: 1, # Garmin
      product: PRODUCT_ID,
      serial_number: 0,
    })

    write_message(:course, { name: opts[:name] })

    write_message(:lap, {
      start_time: start_time,
      timestamp: start_time,
      total_elapsed_time: duration,
      total_timer_time: duration,
      start_x: opts[:start_x],
      start_y: opts[:start_y],
      end_x: opts[:end_x],
      end_y: opts[:end_y],
      total_distance: opts[:total_distance]
    })

    write_message(:event, {
      timestamp: start_time,
      event: :timer,
      event_type: :start,
      event_group: 0
    })

    yield

    write_message(:event, {
      timestamp: start_time + duration,
      event: :timer,
      event_type: :stop_disable_all,
      event_group: 0
    })

    write_data(RubyFit::MessageWriter.crc(@data_crc))
    @state = nil
  end

  # Writes an Activity FIT file.
  # Assumes a single lap and session for the entire activity.
  # Required opts:
  #   :start_time (Time or Integer timestamp)
  #   :duration (Integer seconds)
  #   :track_point_count (Integer)
  #   :time_created (Time or Integer timestamp)
  #   :total_distance (Integer centimeters)
  #   :sport (Symbol, e.g., :running, see MessageConstants::SPORT)
  #   :sub_sport (Symbol, e.g., :generic, see MessageConstants::SUB_SPORT)
  # Optional opts (used in lap/session messages):
  #   :start_x, :start_y, :end_x, :end_y lat/long coordinates
  #   :total_calories, :total_ascent, :total_descent, :avg_speed, :max_speed, etc.
  def write_activity(stream, opts = {})
    raise "Can't start write mode from #{@state}" if @state
    @state = :write
    @local_nums = {}
    @last_local_num = -1

    @stream = stream

    required_opts = %i(start_time duration track_point_count time_created total_distance sport sub_sport)
    required_opts.each do |key|
      raise ArgumentError.new("Missing required option #{key}") unless opts[key]
    end

    start_time = opts[:start_time].to_i
    duration = opts[:duration].to_i
    end_time = opts[:end_time]&.to_i || start_time + duration

    @data_crc = 0

    # Calculate size based on activity messages
    data_size = calculate_activity_data_size(opts[:track_point_count])
    write_data(RubyFit::MessageWriter.file_header(data_size))

    # File ID Message
    write_message(:file_id, {
      time_created: opts[:time_created].to_i,
      type: 4, # Activity file
      manufacturer: 1, # Garmin
      product: PRODUCT_ID,
      serial_number: 0
    })

    # 2. Event Message, Start
    write_message(:event, {
      timestamp: start_time,
      event: :timer,
      event_type: :start,
      event_group: 0
    })

    # 3. Record Messages
    yield # put the track points here

    # 4. Event Message, Stop
    write_message(:event, {
      timestamp: end_time,
      event: :timer,
      event_type: :stop_disable_all, # Use stop_disable_all for final event
      event_group: 0
    })

    # 5. Lap Message, One lap for the whole activity
    lap_data = {
      message_index: 0, # First lap
      timestamp: end_time, # Lap end time
      start_time: start_time,
      total_elapsed_time: duration,
      total_timer_time: duration,
      total_distance: opts[:total_distance],
      # Optional position data
      start_x: opts[:start_x],
      start_y: opts[:start_y],
      end_x: opts[:end_x],
      end_y: opts[:end_y]
    }
    write_message(:lap, lap_data)

    # 6. Session Message, Summarize Lap
    session_data = {
      message_index: 0, # First session
      timestamp: end_time, # Session end time
      start_time: start_time,
      total_elapsed_time: duration,
      total_timer_time: duration,
      num_laps: 1,
      first_lap_index: 0,
      event: :session, # needed for end of session event
      event_type: :stop, # needed for end of session event
      trigger: :activity_end,
      # positional data
      start_position_lat: opts[:start_y],
      start_position_long: opts[:start_x],
      nec_lat: opts[:nec_y] || opts[:end_y],
      nec_long: opts[:nec_x] || opts[:end_x],
      swc_lat: opts[:swc_y] || opts[:start_y],
      swc_long: opts[:swc_x] || opts[:start_x],
      # important fields
      sport: opts[:sport] || :cycling,
      sub_sport: opts[:sub_sport] || :generic
    }.merge(
      # Add optional session fields if available
      opts.select { |k, _| %i[total_ascent total_descent avg_speed total_calories total_distance max_speed].include?(k) }
    ) # Merge common optional fields
    write_message(:session, session_data)

    activity_data = {
      timestamp: end_time,
      total_timer_time: duration,
      num_sessions: 1,
      # limited amounts of activity types
      type: %i[running cycling transition fitness_equipment swimming].include?(opts[:sport]) ? opts[:sport] : :generic,
      event: :activity,
      event_type: :stop
      # local_timestamp: opts[:local_timestamp] # very unsure about this.
   }
    # 7. Activity Message
    write_message(:activity, activity_data)

    # 8. Final CRC
    write_data(RubyFit::MessageWriter.crc(@data_crc))
    @state = nil
  end

  # Course writing methods remain unchanged
  def course_points
    raise "Can only start course points mode inside 'write' block" if @state != :write
    @state = :course_points
    yield
    @state = :write
  end

  def track_points
    raise "Can only write track points inside 'write' block" if @state != :write
    @state = :track_points
    yield
    @state = :write
  end

  def course_point(values)
    raise "Can only write course points inside 'course_points' block" if @state != :course_points
    write_message(:course_point, values)
  end

  def track_point(values)
    raise "Can only write track points inside 'track_points' block" if @state != :track_points
    write_message(:record, values)
  end

  protected

  def write_message(type, values)
    local_num = @local_nums[type]
    unless local_num
      @last_local_num += 1
      local_num = @last_local_num
      @local_nums[type] = local_num
      write_data(RubyFit::MessageWriter.definition_message(type, local_num))
    end

    write_data(RubyFit::MessageWriter.data_message(type, local_num, values))
  end

  def write_data(data)
    @stream.write(data)
    prev = @data_crc
    @data_crc = RubyFit::CRC.update_crc(@data_crc, data)
  end

  # Calculates data size for a Course FIT file
  def calculate_data_size(course_point_count, track_point_count)
    record_counts = {
      file_id: 1,
      course: 1,
      lap: 1,
      event: 2,
      course_point: course_point_count || 0,
      record: track_point_count || 0
    }
    calculate_total_size(record_counts)
  end

  # calculates data size for an Activity FIT file
  def calculate_activity_data_size(track_point_count)
    record_counts = {
      file_id: 1,
      event: 2, # Start, Stop
      record: track_point_count || 0,
      lap: 1,
      session: 1,
      activity: 1
    }
    calculate_total_size(record_counts)
  end

  # helper method to calculate the total size of the FIT file
  def calculate_total_size(record_counts)
    # ensure we have not double counting by tracking with records have already been processed
    definition_sizes_accounted = Set.new
    total_size = 0
    record_counts.each do |type, count|
      next if count.zero?

      # add definition size only once per message type
      unless definition_sizes_accounted.include?(type)
        total_size += RubyFit::MessageWriter.definition_message_size(type)
        definition_sizes_accounted.add(type)
      end

      # add data size for all instances of the message
      total_size += RubyFit::MessageWriter.data_message_size(type) * count
    end
    total_size
  end
end
