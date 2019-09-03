require 'spec_helper'
require 'date'
require 'json'

describe RubyFit::Writer do
  include RubyFit::Helpers

  let(:track_points) {
    [
      {x: -122.64424, y: 45.5279, distance: 0, elevation: 100.0},
      {x: -122.64355, y: 45.5279, distance: 53.81, elevation: 110.1},
      {x: -122.64343, y: 45.52791, distance: 63.234, elevation: 120.2},
      {x: -122.64342, y: 45.52858, distance: 137.822, elevation: 109.3},
      {x: -122.64251, y: 45.52858, distance: 208.788, elevation: 122.4}
    ]
  }

  let(:course_points) {
    [
      {x: -122.64343, y: 45.52791, type: :left, name: "NE 22nd Ave", distance: 63.234},
      {x: -122.64342, y: 45.52858, type: :right, name: "NE Oregon St", distance: 137.822}
    ]
  }

  let(:total_distance) { track_points.last[:distance] }

  it "writes a valid FIT file given realistic data" do
    writer = described_class.new
    stream = StringIO.new
    start_time = DateTime.new(2018, 1, 1, 12, 0, 0).to_time.to_i
    duration = 3600
    end_time = start_time + duration

    opts = {
      time_created: start_time,
      start_time: start_time,
      duration: duration,
      start_x: track_points.first[:x],
      start_y: track_points.first[:y],
      end_x: track_points.last[:x],
      end_y: track_points.last[:y],
      total_distance: total_distance,
      name: "test course",
      track_point_count: track_points.size,
      course_point_count: course_points.size,
    }
    
    dist2timestamp = ->(dist) { (start_time + duration * (dist / total_distance)).to_i }

    writer.write(stream, opts) do
      writer.course_points do
        course_points.each do |data|
          writer.course_point(data.merge(timestamp: dist2timestamp[data[:distance]]))
        end
      end

      writer.track_points do
        track_points.each do |data|
          writer.track_point(data.merge(timestamp: dist2timestamp[data[:distance]]))
        end
      end
    end

    File.open("test.fit", "w") do |f|
      f.write(stream.string)
    end

    def timestamp_bytes(timestamp)
      num2bytes(timestamp - RubyFit::Helpers::GARMIN_TIME_OFFSET, 4)
    end

    def position_bytes(pos)
      num2bytes(deg2semicircles(pos), 4)
    end

    def distance_bytes(dist)
      num2bytes((dist * 100).truncate, 4)
    end

    def altitude_bytes(meters)
      num2bytes(((meters + 500) * 5).truncate, 2)
    end

    def duration_bytes(seconds)
      num2bytes((seconds * 1000).truncate, 4)
    end

    # Grab the CRC to compare at the end
    expected_crc = RubyFit::CRC.update_crc(0, stream.string[0...-2])

    bytes = stream.string.unpack("C*")

    bytes = stream.string.unpack("C*")
    data_size = bytes2num(bytes.slice(4, 4), 4, true, false)
    expect(data_size).to eq(bytes.count - 16)

    # File Header
    expected_bytes = [
      14, # Header size
      RubyFit::MessageWriter::FIT_PROTOCOL_VERSION, # Protocol version
      *num2bytes(RubyFit::MessageWriter::FIT_PROFILE_VERSION, 2, false), # Profile version (little endian)
      *num2bytes(data_size, 4, false), # Data size (little endian)
      *".FIT".unpack("C*"), # Data type human readable string
      *num2bytes(0x0000, 2, false) # Header CRC (little endian) (zero)
    ]
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    # file id definition message
    expected_bytes = [
      0x40, # Definition message, local number 0
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
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    # file id data message
    expected_bytes = [
      0, # Data message, local number 0
      0, 0, 0, 0, # Serial number
      *timestamp_bytes(start_time), # Time created
      0, 1, # Manufacturer (garmin)
      *num2bytes(RubyFit::Writer::PRODUCT_ID, 2), # Product
      6, # Type (course file)
    ]
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    # course definition message
    expected_bytes = [
      0x41, # Definition message, local number 1
      0, # Padding
      1, # Big endian
      0, 31, # Global message number
      1, # Field count
      # Fields are 3 bytes each - field ID, size in bytes, type ID
      5, 16, 7, # Name
    ]
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    # course data message
    expected_bytes = [
      1, # Data message, local number 1
      *"test course".unpack("C*"), 0, 0, 0, 0, 0, # Course name and filler zeros
    ]
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    # lap definition message
    expected_bytes = [
      0x42, # Definition message, local number 1
      0, # Padding
      1, # Big endian
      0, 19, # Global message number
      9, # Field count
      # Fields are 3 bytes each - field ID, size in bytes, type ID
      253, 4, 134, # timestamp
      2, 4, 134, # start time
      7, 4, 134, # total elapsed time
      8, 4, 134, # total timer time
      3, 4, 133, # start position lat
      4, 4, 133, # start position long
      5, 4, 133, # end position lat
      6, 4, 133, # end position long
      9, 4, 134, # total distance
    ]
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    # lap data message
    expected_bytes = [
      2, # Data message, local number 2
      *timestamp_bytes(start_time), # timestamp,
      *timestamp_bytes(start_time), # start time
      *duration_bytes(duration), # total elapsed time
      *duration_bytes(duration), # total timer time
      *position_bytes(track_points.first[:y]), # start lat
      *position_bytes(track_points.first[:x]), # start lng
      *position_bytes(track_points.last[:y]), # end lat
      *position_bytes(track_points.last[:x]), # end lng
      *distance_bytes(total_distance), #total_distance
    ]
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    # event definition message
    expected_bytes = [
      0x43, # Definition message, local number 4
      0, # Padding
      1, # Big endian
      0, 21, # Global message number
      4, # Field count
      # Fields are 3 bytes each - field ID, size in bytes, type ID
      253, 4, 134, # timestamp
      0, 1, 0, # event enum
      1, 1, 0, # event_type enum
      4, 1, 2, # event_group
    ]
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    # event data message: timer start
    expected_bytes = [
      0x03, # data message, local number 3
      *timestamp_bytes(start_time), # timestamp
      *num2bytes(0, 1), # event (timer)
      *num2bytes(0, 1), # event_type (start)
      *num2bytes(0, 1), # event_group
    ] 
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    # course point definition message
    expected_bytes = [
      0x44, # Definition message, local number 4
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
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    course_points.each do |data|
      distance = data[:distance]
      timestamp = dist2timestamp[distance]

      # course point data message
      expected_bytes = [
        4, # Data message, local number 4
        *timestamp_bytes(timestamp), # timestamp
        *position_bytes(data[:y]), # lat
        *position_bytes(data[:x]), # lng
        *distance_bytes(distance), # distance
        *str2bytes(data[:name], 16), # name
        255, 255, # message index, invalid
        RubyFit::MessageConstants::COURSE_POINT_TYPE[data[:type]], # type
      ]
      expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)
    end

    # record definition message
    expected_bytes = [
      0x45, # Definition message, local number 5
      0, # Padding
      1, # Big endian
      0, 20, # Global message number
      5, # Field count
      # Fields are 3 bytes each - field ID, size in bytes, type ID
      253, 4, 134, # timestamp
      0, 4, 133, # position lat
      1, 4, 133, # position long
      5, 4, 134, # distance
      2, 2, 132, # altitude
    ]
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)
    
    track_points.each do |data|
      distance = data[:distance]
      timestamp = dist2timestamp[distance]

      # record data message
      expected_bytes = [
        5, # Data message, local number 5
        *timestamp_bytes(timestamp), # timestamp
        *position_bytes(data[:y]), # lat
        *position_bytes(data[:x]), # lng
        *distance_bytes(distance), # distance
        *altitude_bytes(data[:elevation]), # elevation
      ]
      
      expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)
    end
    
    # event data message: timer stop
    expected_bytes = [
      0x03, # data message, local number 3
      *timestamp_bytes(end_time), # timestamp
      *num2bytes(0, 1), # event (timer)
      *num2bytes(9, 1), # event_type (all stop)
      *num2bytes(0, 1), # event_group
    ] 

    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    expected_bytes = num2bytes(expected_crc, 2, false) # CRC (little endian)
    expect(bytes.shift(expected_bytes.size)).to eq(expected_bytes)

    expect(bytes.count).to eq(0)
  end

  it "writes real data to a fit file" do
    writer = described_class.new
    stream = File.open("drummond.fit", "w")

    def deep_symbolize_keys(obj)
      case obj
      when Hash
        obj.map{ |key, val| [key.to_sym, deep_symbolize_keys(val)] }.to_h
      when Array
        obj.map{ |val| deep_symbolize_keys(val) }
      else
        obj
      end
    end
    json_data = File.read("spec/fixtures/drummond.json")
    data = deep_symbolize_keys(JSON.parse(json_data))

    writer.write(stream, data[:opts]) do
      writer.course_points do
        data[:course_points].each do |course_point|
          course_point[:type] = course_point[:type].to_sym
          writer.course_point(course_point)
        end
      end

      writer.track_points do
        data[:track_points].each do |track_point|
          writer.track_point(track_point)
        end
      end
    end

    stream.close
  end
end
