require 'spec_helper'

describe RubyFit::MessageWriter do
  include RubyFit::Helpers

  # check_bytes takes a byte array and an ordered hash of field name
  # (informational only) to expected byte array. For each field, the byte array
  # is shifted by the size of the expected value for the field, and the values
  # are compared. Finally, the length of the byte array is checked to equal the
  # leftover parameter (default 0).
  def check_bytes(bytes, expected_fields, leftover = 0)
    expected_fields.each do |field, expected|
      expected = Array(expected)
      value = bytes.shift(expected.size)
      expect(value).to eq(expected), "Expected '#{field}'\n  to be: #{expected.inspect}\nbut got: #{value.inspect}"
    end
    expect(bytes.length).to eq(leftover)
  end

  let(:writer) { described_class.new }

  describe ".file_header" do
    it "creates a file header" do
      data_size = 0xABADBEEF
      header_bytes = described_class.file_header(data_size)
      expected_bytes = [
        14, # Header size
        RubyFit::MessageWriter::FIT_PROTOCOL_VERSION, # Protocol version
        *num2bytes(RubyFit::MessageWriter::FIT_PROFILE_VERSION, 2, false), # Profile version (little endian)
        *num2bytes(data_size, 4, false), # Data size (little endian)
        *".FIT".unpack("C*"), # Data type human readable string
        *num2bytes(0x0000, 2, false) # CRC (optional zero) (little endian)
      ]
      expect(header_bytes.unpack("C*")).to eq(expected_bytes)
    end
  end

  describe ".crc" do
    it "writes a 16-bit CRC value" do
      crc_value = 0xABCD
      result = described_class.crc(crc_value)
      expect(result.unpack("C*")).to eq(num2bytes(crc_value, 2, false)) # Little endian
    end
  end

  describe ".definition_message" do
    it "creates a valid file_id definition message" do 
      message_bytes = described_class.definition_message(:file_id, 0)
      expected_bytes = [
        make_message_header(definition: true, local_number: 0),
        0, # Padding
        1, # Big endian
        0, 0, # Global message number
        5, # Field count
        # Fields are 3 bytes each - field ID, size in bytes, type ID
        3, 4, 140, # Serial number 
        4, 4, 134, # Time created
        1, 2, 132, # Manufacturer
        2, 2, 132, # Product
        0, 1, 0 # Type
      ]
      expect(message_bytes.unpack("C*")).to eq(expected_bytes)
    end

    it "creates a valid course definition message" do 
      message_bytes = described_class.definition_message(:course, 0)
      expected_bytes = [
        make_message_header(definition: true, local_number: 0),
        0, # Padding
        1, # Big endian
        0, 31, # Global message number
        1, # Field count
        # Fields are 3 bytes each - field ID, size in bytes, type ID
        5, 16, 7, # Name
      ]
      expect(message_bytes.unpack("C*")).to eq(expected_bytes)
    end

    it "creates a valid lap definition message" do 
      message_bytes = described_class.definition_message(:lap, 0)
      bytes = message_bytes.unpack("C*")
      expected_bytes = [
        make_message_header(definition: true, local_number: 0),
        0, # Padding
        1, # Big endian
        0, 19, # Global message number
        7, # Field count
        # Fields are 3 bytes each - field ID, size in bytes, type ID
        253, 4, 134, # timestamp
        2, 4, 134, # start time
        3, 4, 133, # start position lat
        4, 4, 133, # start position long
        5, 4, 133, # end position lat
        6, 4, 133, # end position long
        9, 4, 134, # total distance
      ]
      expect(bytes).to eq(expected_bytes)
    end

    it "creates a valid course_point definition message" do 
      message_bytes = described_class.definition_message(:course_point, 0)
      bytes = message_bytes.unpack("C*")
      expected_bytes = [
        make_message_header(definition: true, local_number: 0),
        0, # Padding
        1, # Big endian
        0, 32, # Global message number
        7, # Field count
        # Fields are 3 bytes each - field ID, size in bytes, type ID
        1, 4, 134, # timestamp
        2, 4, 133, # position lat
        3, 4, 133, # position long
        4, 4, 134, # distance
        6, 16, 7, # name
        254, 2, 132, # message_index
        5, 1, 0, # type
      ]
      expect(bytes).to eq(expected_bytes)
    end

    it "creates a valid record definition message" do 
      message_bytes = described_class.definition_message(:record, 0)
      bytes = message_bytes.unpack("C*")
      expected_bytes = [
        make_message_header(definition: true, local_number: 0),
        0, # Padding
        1, # Big endian
        0, 20, # Global message number
        5, # Field count
        # Fields are 3 bytes each - field ID, size in bytes, type ID
        253, 4, 134, # timestamp
        0, 4, 133, # position lat
        1, 4, 133, # position long
        5, 4, 134, # distance
        2, 2, 132, # elevation
      ]
      expect(bytes).to eq(expected_bytes)
    end
  end

  describe ".data_message" do
    it "creates a valid file_id data message" do
      timestamp = Time.now.to_i
      expected_fit_timestamp = num2bytes(timestamp - RubyFit::Helpers::GARMIN_TIME_OFFSET, 4)
      values = {
        time_created: timestamp,
        manufacturer: 1, # Garmin
        type: 6, # Course File
        product: 0,
        serial_number: 0,
      }
      message_bytes = described_class.data_message(:file_id, 0, values)
      bytes = message_bytes.unpack("C*")
      expect(bytes.shift(1)).to eq([make_message_header(local_number: 0)]) # Header
      expect(bytes.shift(4)).to eq(num2bytes(0, 4)) # Serial number
      expect(bytes.shift(4)).to eq(expected_fit_timestamp) # Time created
      expect(bytes.shift(2)).to eq(num2bytes(1, 2)) # Manufacturer (garmin)
      expect(bytes.shift(2)).to eq(num2bytes(0, 2)) # Product
      expect(bytes.shift(1)).to eq([6]) # Type (course file)
      expect(bytes.size).to eq(0)
    end

    context "with course messages" do
      def test_result(bytes, expected_name)
        expect(bytes.shift(1)).to eq([make_message_header(local_number: 0)]) # Header
        expect(bytes.shift(16)).to eq(str2bytes(expected_name, 16)) # Name
        expect(bytes.size).to eq(0)
      end

      it "creates a valid message" do 
        message_bytes = described_class.data_message(:course, 0, name: "foo")
        bytes = message_bytes.unpack("C*")
        test_result(bytes, "foo")
      end

      it "truncates names longer than 15 characters" do 
        message_bytes = described_class.data_message(:course, 0, name: "1234567890abcdefghij")
        bytes = message_bytes.unpack("C*")
        test_result(bytes, "1234567890abcde")
      end
    end

    it "creates a valid lap data message" do 
      start_time = Time.now.to_i
      end_time = start_time + 3600
      distance = 12345.6789

      expected_fit_start_time = num2bytes(start_time - RubyFit::Helpers::GARMIN_TIME_OFFSET, 4)
      expected_fit_end_time = num2bytes(end_time - RubyFit::Helpers::GARMIN_TIME_OFFSET, 4)
      expected_fit_distance = (distance * 100).truncate

      invalid_position = num2bytes(2**31 - 1, 4)

      values = {
        start_time: start_time,
        timestamp: end_time,
        total_distance: distance
      }
      message_bytes = described_class.data_message(:lap, 0, values )
      bytes = message_bytes.unpack("C*")
      expect(bytes.shift(1)).to eq([make_message_header(local_number: 0)]) # Header
      expect(bytes.shift(4)).to eq(expected_fit_end_time) # timestamp (end time)
      expect(bytes.shift(4)).to eq(expected_fit_start_time) # start time
      expect(bytes.shift(4)).to eq(invalid_position) # start lat (invalid)
      expect(bytes.shift(4)).to eq(invalid_position) # start lng (invalid)
      expect(bytes.shift(4)).to eq(invalid_position) # end lat (invalid)
      expect(bytes.shift(4)).to eq(invalid_position) # end lng (invalid)
      expect(bytes.shift(4)).to eq(num2bytes(expected_fit_distance, 4)) # total_distance
    end

    context "with course point messasges" do
      def test_result(bytes, opts)
        y = opts[:y] ? deg2semicircles(opts[:y]) : -1
        x = opts[:x] ? deg2semicircles(opts[:x]) : -1
        fields = {
          header: [make_message_header(local_number: 0)],
          timestamp: num2bytes(opts[:timestamp] - RubyFit::Helpers::GARMIN_TIME_OFFSET, 4),
          y: num2bytes(y, 4),
          x: num2bytes(x, 4),
          distance: num2bytes(((opts[:distance] || 0) * 100).floor, 4),
          name: str2bytes(opts[:name] || "", 16),
          message_index: [0xFF, 0xFF], # invalid
          type: [7], # "right"
        }
        check_bytes(bytes, fields)
      end

      it "creates a valid message" do 
        opts = {
          timestamp: Time.now.to_i,
          type: :right,
          y: 45.5,
          x: -122.0,
          distance: 12_000,
          name: "foobar"
        }

        message_bytes = described_class.data_message(:course_point, 0, opts)
        bytes = message_bytes.unpack("C*")
        test_result(bytes, opts)
      end

      it "leaves omitted fields as their default value" do 
        opts = {
          timestamp: Time.now.to_i,
          type: :right,
          y: 45.5,
          x: -122.0,
          distance: 12_000,
          name: "foobar"
        }

        message_bytes = described_class.data_message(:course_point, 0, opts)
        bytes = message_bytes.unpack("C*")
        test_result(bytes, opts)
      end
    end
    
    it "creates a valid record data message" do 
      timestamp = Time.now.to_i
      y = 45.5
      x = -122.0
      distance = 12345.6789

      expected_timestamp = num2bytes(timestamp - RubyFit::Helpers::GARMIN_TIME_OFFSET, 4)
      expected_fit_distance = (distance * 100).truncate

      values = {
        timestamp: timestamp,
        y: y,
        x: x,
        distance: distance
      }
      message_bytes = described_class.data_message(:record, 0, values )
      bytes = message_bytes.unpack("C*")
      expect(bytes.shift(1)).to eq([make_message_header(local_number: 0)]) # Header
      expect(bytes.shift(4)).to eq(expected_timestamp) # timestamp
      expect(bytes.shift(4)).to eq(num2bytes(deg2semicircles(y), 4)) # lat
      expect(bytes.shift(4)).to eq(num2bytes(deg2semicircles(x), 4)) # lng
      expect(bytes.shift(4)).to eq(num2bytes(expected_fit_distance, 4)) # distance
    end
  end

  describe ".definition_message_size" do
    it "returns the correct value for :file_id" do 
      expect(described_class.definition_message_size(:file_id)).to eq(6 + 5*3)
    end

    it "returns the correct value for :course" do 
      expect(described_class.definition_message_size(:course)).to eq(6 + 1*3)
    end

    it "returns the correct value for :lap" do 
      expect(described_class.definition_message_size(:lap)).to eq(6 + 7*3)
    end

    it "returns the correct value for :course_point" do 
      expect(described_class.definition_message_size(:course_point)).to eq(6 + 7*3)
    end

    it "returns the correct value for :record" do 
      expect(described_class.definition_message_size(:record)).to eq(6 + 5*3)
    end
  end

  describe ".data_message_size" do
    it "returns the correct value for :file_id" do 
      expect(described_class.data_message_size(:file_id)).to eq(14)
    end

    it "returns the correct value for :course" do 
      expect(described_class.data_message_size(:course)).to eq(17)
    end

    it "returns the correct value for :lap" do 
      expect(described_class.data_message_size(:lap)).to eq(29)
    end

    it "returns the correct value for :course_point" do 
      expect(described_class.data_message_size(:course_point)).to eq(36)
    end

    it "returns the correct value for :record" do 
      expect(described_class.data_message_size(:record)).to eq(19)
    end
  end
end
