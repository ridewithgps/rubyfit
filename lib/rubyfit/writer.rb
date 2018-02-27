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

  def calculate_data_size(course_point_count, track_point_count)
    record_counts = {
      file_id: 1,
      course: 1,
      lap: 1,
      event: 2,
      course_point: course_point_count, 
      record: track_point_count,
    }

    data_sizes = record_counts.map do |type, count|
      def_size = RubyFit::MessageWriter.definition_message_size(type)
      data_size = RubyFit::MessageWriter.data_message_size(type) * count 
      result = def_size + data_size
      puts "#{type}: #{result}"
      result
    end

    data_sizes.reduce(&:+)
  end
end
