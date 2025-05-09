require "rubyfit/type"
require "rubyfit/helpers"
require "rubyfit/message_constants"

class RubyFit::MessageWriter
  extend RubyFit::Helpers

  FIT_PROTOCOL_VERSION = 0x10 # major 1, minor 0
  FIT_PROFILE_VERSION = 1 * 100 + 52 # major 1, minor 52

  MESSAGE_DEFINITIONS = {
    file_id: {
      id: 0,
      fields: {
        serial_number: { id: 3, type: RubyFit::Type.uint32z, required: true },
        time_created: { id: 4, type: RubyFit::Type.timestamp, required: true },
        manufacturer: { id: 1, type: RubyFit::Type.uint16 }, # See FIT_MANUFACTURER_*
        product: { id: 2, type: RubyFit::Type.uint16 },
        type: { id: 0, type: RubyFit::Type.enum, required: true } # See FIT_FILE_*
      }
    },
    course: {
      id: 31,
      fields: {
        name: { id: 5, type: RubyFit::Type.string(16), required: true }
      }
    },
    activity: {
      id: 34, # fit_example.h line 92
      fields: { # fit_example.h line 5001
        timestamp: { id: 253, type: RubyFit::Type.timestamp, required: true },
        total_timer_time: { id: 0, type: RubyFit::Type.duration, required: true },
        num_sessions: { id: 1, type: RubyFit::Type.uint16, required: true },
        type: { id: 2, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::ACTIVITY_TYPE, required: true },
        event: { id: 3, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::EVENT, required: true },
        event_type: { id: 4, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::EVENT_TYPE, required: true },
        event_group: { id: 6, type: RubyFit::Type.uint8 }
      }
    },
    session: {
      id: 18, # fit_example.h line 80
      fields: {
        timestamp: { id: 253, type: RubyFit::Type.timestamp, required: true },
        start_time: { id: 2, type: RubyFit::Type.timestamp, required: true },
        start_position_lat: { id: 3, type: RubyFit::Type.semicircles },
        start_position_long: { id: 4, type: RubyFit::Type.semicircles },
        total_elapsed_time: { id: 7, type: RubyFit::Type.duration, required: true },
        total_timer_time: { id: 8, type: RubyFit::Type.duration },
        total_distance: { id: 9, type: RubyFit::Type.centimeters, required: true },
        total_cycles: { id: 10, type: RubyFit::Type.uint32 },
        nec_lat: { id: 29, type: RubyFit::Type.semicircles },
        nec_long: { id: 30, type: RubyFit::Type.semicircles },
        swc_lat: { id: 31, type: RubyFit::Type.semicircles },
        swc_long: { id: 32, type: RubyFit::Type.semicircles },
        end_position_lat: { id: 38, type: RubyFit::Type.semicircles },
        end_position_long: { id: 39, type: RubyFit::Type.semicircles },
        avg_stroke_count: { id: 41, type: RubyFit::Type.uint32 },
        total_work: { id: 48, type: RubyFit::Type.uint32 },
        total_moving_time: { id: 59, type: RubyFit::Type.duration },
        # these are arrays, not supported yet
        # time_in_hr_zone: NOT SUPPORTED
        # time_in_speed_zone: NOT SUPPORTED
        # time_in_cadence_zone: NOT SUPPORTED
        # time_in_power_zone: NOT SUPPORTED
        sport_profile_name: { id: 110, type: RubyFit::Type.string(16) },
        avg_lap_time: { id: 69, type: RubyFit::Type.duration },
        enhanced_avg_speed: { id: 124, type: RubyFit::Type.uint32 },
        enhanced_max_speed: { id: 125, type: RubyFit::Type.uint32 },
        enhanced_avg_altitude: { id: 126, type: RubyFit::Type.altitude32 },
        enhanced_min_altitude: { id: 127, type: RubyFit::Type.altitude32 },
        enhanced_max_altitude: { id: 128, type: RubyFit::Type.altitude32 },
        message_index: { id: 254, type: RubyFit::Type.uint16 },
        total_calories: { id: 11, type: RubyFit::Type.uint16 },
        total_fat_calories: { id: 13, type: RubyFit::Type.uint16 },
        avg_speed: { id: 14, type: RubyFit::Type.uint16 },
        max_speed: { id: 15, type: RubyFit::Type.uint16 },
        avg_power: { id: 20, type: RubyFit::Type.uint16 },
        max_power: { id: 21, type: RubyFit::Type.uint16 },
        total_ascent: { id: 22, type: RubyFit::Type.uint16 },
        total_descent: { id: 23, type: RubyFit::Type.uint16 },
        first_lap_index: { id: 25, type: RubyFit::Type.uint16 },
        num_laps: { id: 26, type: RubyFit::Type.uint16 },
        num_lengths: { id: 33, type: RubyFit::Type.uint16 },
        normalized_power: { id: 34, type: RubyFit::Type.uint16 },
        training_stress_score: { id: 35, type: RubyFit::Type.uint16 },
        intensity_factor: { id: 36, type: RubyFit::Type.uint16 },
        left_right_balance: { id: 37, type: RubyFit::Type.uint16 },
        avg_stroke_distance: { id: 42, type: RubyFit::Type.uint16 },
        pool_length: { id: 44, type: RubyFit::Type.uint16 },
        threshold_power: { id: 45, type: RubyFit::Type.uint16 },
        num_active_lengths: { id: 47, type: RubyFit::Type.uint16 },
        avg_altitude: { id: 49, type: RubyFit::Type.altitude },
        max_altitude: { id: 50, type: RubyFit::Type.altitude },
        avg_grade: { id: 52, type: RubyFit::Type.sint16 },
        avg_pos_grade: { id: 53, type: RubyFit::Type.sint16 },
        avg_neg_grade: { id: 54, type: RubyFit::Type.sint16 },
        max_pos_grade: { id: 55, type: RubyFit::Type.sint16 },
        max_neg_grade: { id: 56, type: RubyFit::Type.sint16 },
        avg_pos_vertical_speed: { id: 60, type: RubyFit::Type.sint16 },
        avg_neg_vertical_speed: { id: 61, type: RubyFit::Type.sint16 },
        max_pos_vertical_speed: { id: 62, type: RubyFit::Type.sint16 },
        max_neg_vertical_speed: { id: 63, type: RubyFit::Type.sint16 },
        best_lap_index: { id: 70, type: RubyFit::Type.uint16 },
        min_altitude: { id: 71, type: RubyFit::Type.altitude },
        player_score: { id: 82, type: RubyFit::Type.uint16 },
        opponent_score: { id: 83, type: RubyFit::Type.uint16 },
        # these are arrays, not supported yet
        # stroke_count: { id: 85, type: RubyFit::Type.uint16 },
        # zone_count: { id: 86, type: RubyFit::Type.uint16 },
        max_ball_speed: { id: 87, type: RubyFit::Type.uint16 },
        avg_ball_speed: { id: 88, type: RubyFit::Type.uint16 },
        avg_vertical_oscillation: { id: 89, type: RubyFit::Type.uint16 },
        avg_stance_time_percent: { id: 90, type: RubyFit::Type.uint16 },
        avg_stance_time: { id: 91, type: RubyFit::Type.uint16 },
        avg_vam: { id: 139, type: RubyFit::Type.uint16 },
        event: { id: 0, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::EVENT, required: true },
        event_type: { id: 1, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::EVENT_TYPE, required: true },
        sport: { id: 5, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::SPORT, required: true },
        sub_sport: { id: 6, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::SUB_SPORT, required: true },
        avg_heart_rate: { id: 16, type: RubyFit::Type.uint8 },
        max_heart_rate: { id: 17, type: RubyFit::Type.uint8 },
        avg_cadence: { id: 18, type: RubyFit::Type.uint8 },
        max_cadence: { id: 19, type: RubyFit::Type.uint8 },
        total_training_effect: { id: 24, type: RubyFit::Type.uint8 },
        event_group: { id: 27, type: RubyFit::Type.uint8 },
        trigger: { id: 28, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::SESSION_TRIGGER },
        # not default values for enums, will throw error if included
        # swim_stroke: { id: 43, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::SWIM_STROKE },
        # pool_length_unit: { id: 46, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::DISPLAY_MEASURE },
        gps_accuracy: { id: 51, type: RubyFit::Type.uint8 },
        avg_temperature: { id: 57, type: RubyFit::Type.sint8 },
        max_temperature: { id: 58, type: RubyFit::Type.sint8 },
        min_heart_rate: { id: 64, type: RubyFit::Type.uint8 },
        opponent_name: { id: 84, type: RubyFit::Type.string(1) },
        avg_fractional_cadence: { id: 92, type: RubyFit::Type.uint8 },
        max_fractional_cadence: { id: 93, type: RubyFit::Type.uint8 },
        total_fractional_cycles: { id: 94, type: RubyFit::Type.uint8 },
        sport_index: { id: 111, type: RubyFit::Type.uint8 },
        total_anaerobic_training_effect: { id: 137, type: RubyFit::Type.uint8 },
        min_temperature: { id: 150, type: RubyFit::Type.sint8 }
      }
    },
    lap: {
      id: 19,
      fields: {
        timestamp: { id: 253, type: RubyFit::Type.timestamp, required: true },
        start_time: { id: 2, type: RubyFit::Type.timestamp, required: true },
        total_elapsed_time: { id: 7, type: RubyFit::Type.duration, required: true },
        total_timer_time: { id: 8, type: RubyFit::Type.duration, required: true },
        start_y: { id: 3, type: RubyFit::Type.semicircles },
        start_x: { id: 4, type: RubyFit::Type.semicircles },
        end_y: { id: 5, type: RubyFit::Type.semicircles },
        end_x: { id: 6, type: RubyFit::Type.semicircles },
        total_distance: { id: 9, type: RubyFit::Type.centimeters }
      }
    },
    course_point: {
      id: 32,
      fields: {
        timestamp: { id: 1, type: RubyFit::Type.timestamp, required: true },
        y: { id: 2, type: RubyFit::Type.semicircles, required: true },
        x: { id: 3, type: RubyFit::Type.semicircles, required: true },
        distance: { id: 4, type: RubyFit::Type.centimeters },
        name: { id: 6, type: RubyFit::Type.string(16) },
        message_index: { id: 254, type: RubyFit::Type.uint16 },
        type: { id: 5, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::COURSE_POINT_TYPE, required: true }
      }
    },
    record: {
      id: 20,
      fields: {
        timestamp: { id: 253, type: RubyFit::Type.timestamp, required: true },
        y: { id: 0, type: RubyFit::Type.semicircles },
        x: { id: 1, type: RubyFit::Type.semicircles },
        distance: { id: 5, type: RubyFit::Type.centimeters },
        elevation: { id: 2, type: RubyFit::Type.altitude },
        # new fields for activity type
        heart_rate: { id: 3, type: RubyFit::Type.uint8 },
        cadence: { id: 4, type: RubyFit::Type.uint8 },
        power: { id: 7, type: RubyFit::Type.uint16 }
      }
    },
    # activity_record: {
    #   id: 20,
    #   fields: {
    #     timestamp: { id: 253, type: RubyFit::Type.timestamp, required: true },
    #     y: { id: 0, type: RubyFit::Type.semicircles, required: true },
    #     x: { id: 1, type: RubyFit::Type.semicircles, required: true },
    #     distance: { id: 5, type: RubyFit::Type.centimeters },
    #     elevation: { id: 2, type: RubyFit::Type.altitude },
    #     # new fields for activity type
    #     heart_rate: { id: 3, type: RubyFit::Type.uint8 },
    #     cadence: { id: 4, type: RubyFit::Type.uint8 },
    #     power: { id: 7, type: RubyFit::Type.uint16 }
    #   }
    # },
    event: {
      id: 21,
      fields: {
        timestamp: { id: 253, type: RubyFit::Type.timestamp, required: true },
        event: { id: 0, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::EVENT, required: true },
        event_type: { id: 1, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::EVENT_TYPE, required: true },
        event_group: { id: 4, type: RubyFit::Type.uint8 }
      }
    }
  }

  def self.definition_message(type, local_num)
    pack_bytes do |bytes|
      message_data = MESSAGE_DEFINITIONS[type]
      bytes << header_byte(local_num, true)
      bytes << 0x00 # Reserved uint8
      bytes << 0x01 # Big endian
      bytes.push(*num2bytes(message_data[:id], 2)) # Global message ID
      bytes << message_data[:fields].size # Field count

      message_data[:fields].each do |_field, info|
        type = info[:type]
        bytes << info[:id]
        bytes << type.byte_count
        bytes << type.fit_id
      end
    end
  end

  def self.data_message(type, local_num, values)
    pack_bytes do |bytes|
      message_data = MESSAGE_DEFINITIONS[type]
      bytes << header_byte(local_num, false)
      message_data[:fields].each do |field, info|
        field_type = info[:type]
        value = values[field]
        if info[:required] && value.nil?
          raise ArgumentError, "Missing required field '#{field}' in #{type} data message values"
        end

        if info[:values]
          value = info[:values][value]
          if value.nil?
            raise ArgumentError, "Invalid value for '#{field}' in #{type} data message values"
          end
        end

        value_bytes = value ? field_type.val2bytes(value) : field_type.default_bytes
        bytes.push(*value_bytes)
      end
    end
  end

  def self.definition_message_size(type)
    message_data = MESSAGE_DEFINITIONS[type]
    raise ArgumentError, "Unknown message type '#{type}'" unless message_data

    6 + message_data[:fields].count * 3
  end

  def self.data_message_size(type)
    message_data = MESSAGE_DEFINITIONS[type]
    raise ArgumentError, "Unknown message type '#{type}'" unless message_data

    1 + message_data[:fields].values.map { |info| info[:type].byte_count }.reduce(&:+)
  end

  def self.file_header(data_byte_count = 0)
    pack_bytes do |bytes|
      bytes << 14 # Header size
      bytes << FIT_PROTOCOL_VERSION # Protocol version
      bytes.push(*num2bytes(FIT_PROFILE_VERSION, 2).reverse) # Profile version (little endian)
      bytes.push(*num2bytes(data_byte_count, 4).reverse) # Data size (little endian)
      bytes.push(*str2bytes(".FIT", 5).take(4)) # Data Type ASCII, no terminator
      crc = 0 # RubyFit::CRC.update_crc(0, bytes2str(bytes))
      bytes.push(*num2bytes(crc, 2).reverse) # Header CRC (little endian)
    end
  end

  def self.crc(crc_value)
    pack_bytes do |bytes|
      bytes.push(*num2bytes(crc_value, 2, false)) # Little endian
    end
  end

  # Internal

  def self.header_byte(local_number, definition)
    local_number & 0xF | (definition ? 0x40 : 0x00)
  end

  def self.pack_bytes
    bytes = []
    yield bytes
    bytes.pack("C*")
  end
end
