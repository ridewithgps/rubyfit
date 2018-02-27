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
        type: { id: 0, type: RubyFit::Type.enum, required: true }, # See FIT_FILE_*
      }
    },
    course: {
      id: 31,
      fields: {
        name: { id: 5, type: RubyFit::Type.string(16), required: true },
      }
    },
    lap: {
      id: 19,
      fields: {
        timestamp: { id: 253, type: RubyFit::Type.timestamp, required: true},
        start_time: { id: 2, type: RubyFit::Type.timestamp, required: true},
        total_elapsed_time: { id: 7, type: RubyFit::Type.duration, required: true }, 
        total_timer_time: { id: 8, type: RubyFit::Type.duration, required: true }, 
        start_y: { id: 3, type: RubyFit::Type.semicircles },
        start_x: { id: 4, type: RubyFit::Type.semicircles },
        end_y: { id: 5, type: RubyFit::Type.semicircles },
        end_x: { id: 6, type: RubyFit::Type.semicircles },
        total_distance: { id: 9, type: RubyFit::Type.centimeters },
      },
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
      },
    },
    record: {
      id: 20,
      fields: {
        timestamp: { id: 253, type: RubyFit::Type.timestamp, required: true },
        y: { id: 0, type: RubyFit::Type.semicircles, required: true },
        x: { id: 1, type: RubyFit::Type.semicircles, required: true },
        distance: { id: 5, type: RubyFit::Type.centimeters },
        elevation: { id: 2, type: RubyFit::Type.altitude },
      }
    },
    event: {
      id: 21,
      fields: {
        timestamp: { id: 253, type: RubyFit::Type.timestamp, required: true },
        event: { id: 0, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::EVENT, required: true },
        event_type: { id: 1, type: RubyFit::Type.enum, values: RubyFit::MessageConstants::EVENT_TYPE, required: true },
        event_group: { id: 4, type: RubyFit::Type.uint8 },
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

      message_data[:fields].each do |field, info|
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
          raise ArgumentError.new("Missing required field '#{field}' in #{type} data message values")
        end

        if info[:values]
          value = info[:values][value]
          if value.nil?
            raise ArgumentError.new("Invalid value for '#{field}' in #{type} data message values")
          end
        end

        value_bytes = value ? field_type.val2bytes(value) : field_type.default_bytes
        bytes.push(*value_bytes)
      end
    end
  end

  def self.definition_message_size(type)
    message_data = MESSAGE_DEFINITIONS[type]
    raise ArgumentError.new("Unknown message type '#{type}'") unless message_data
    6 + message_data[:fields].count * 3
  end

  def self.data_message_size(type)
    message_data = MESSAGE_DEFINITIONS[type]
    raise ArgumentError.new("Unknown message type '#{type}'") unless message_data
    1 + message_data[:fields].values.map{|info| info[:type].byte_count}.reduce(&:+)
  end

  def self.file_header(data_byte_count = 0) 
    pack_bytes do |bytes|
      bytes << 14 # Header size
      bytes << FIT_PROTOCOL_VERSION # Protocol version
      bytes.push(*num2bytes(FIT_PROFILE_VERSION, 2).reverse) # Profile version (little endian)
      bytes.push(*num2bytes(data_byte_count, 4).reverse) # Data size (little endian)
      bytes.push(*str2bytes(".FIT", 5).take(4)) # Data Type ASCII, no terminator
      crc = 0 #RubyFit::CRC.update_crc(0, bytes2str(bytes))
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
