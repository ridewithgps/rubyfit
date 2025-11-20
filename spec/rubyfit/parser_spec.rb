require 'spec_helper'
require 'date'

describe RubyFit::FitParser do
  describe "#parse" do
    let(:start_time) { DateTime.new(2025, 1, 1, 12, 0, 0).to_time.to_i }

    let(:test_fit_data) do
      # Generate a simple FIT file for testing
      writer = RubyFit::Writer.new
      stream = StringIO.new

      track_points = [
        {x: -122.64424, y: 45.5279, distance: 0, elevation: 100.0},
        {x: -122.64355, y: 45.5279, distance: 53.81, elevation: 150.0}
      ]

      opts = {
        time_created: start_time,
        start_time: start_time,
        duration: 100,
        start_x: track_points.first[:x],
        start_y: track_points.first[:y],
        end_x: track_points.last[:x],
        end_y: track_points.last[:y],
        total_distance: track_points.last[:distance],
        name: "test course",
        track_point_count: track_points.size,
        course_point_count: 0,
      }

      writer.write(stream, opts) do
        writer.course_points { }
        writer.track_points do
          track_points.each_with_index do |data, i|
            writer.track_point(data.merge(timestamp: start_time + i * 50))
          end
        end
      end

      stream.string
    end

    it "parses a FIT file and verifies all data from opts" do
      callbacks = TestCallbacks.new
      parser = RubyFit::FitParser.new(callbacks)

      parser.parse(test_fit_data)

      # Verify file_id fields
      expect(callbacks.file_id["type"]).to eq(6) # Course file type
      expect(callbacks.file_id["manufacturer"]).to eq(1) # Garmin
      expect(callbacks.file_id["product"]).to eq(RubyFit::Writer::GARMIN_CONNECT_PRODUCT_ID) # 65534
      expect(callbacks.file_id["time_created"]).to eq(start_time)

      # Verify lap fields
      expect(callbacks.lap["start_time"]).to eq(start_time)
      expect(callbacks.lap["timestamp"]).to eq(start_time)
      expect(callbacks.lap["total_elapsed_time"]).to eq(100000) # duration in milliseconds
      expect(callbacks.lap["total_timer_time"]).to eq(100.0) # duration in seconds (divided by 1000)
      expect(callbacks.lap["start_position_lat"]).to be_within(0.00001).of(45.5279)
      expect(callbacks.lap["start_position_long"]).to be_within(0.00001).of(-122.64424)
      expect(callbacks.lap["end_position_lat"]).to be_within(0.00001).of(45.5279)
      expect(callbacks.lap["end_position_long"]).to be_within(0.00001).of(-122.64355)
      expect(callbacks.lap["total_distance"]).to be_within(0.01).of(53.81)

      # Verify track points
      expect(callbacks.records.size).to eq(2)
      expect(callbacks.records[0]["position_lat"]).to be_within(0.00001).of(45.5279)
      expect(callbacks.records[0]["position_long"]).to be_within(0.00001).of(-122.64424)
      expect(callbacks.records[0]["altitude"]).to eq(100.0)
      expect(callbacks.records[1]["position_lat"]).to be_within(0.00001).of(45.5279)
      expect(callbacks.records[1]["position_long"]).to be_within(0.00001).of(-122.64355)
      expect(callbacks.records[1]["altitude"]).to eq(150.0)

      # Verify events
      expect(callbacks.events.size).to eq(2) # start and stop events
    end
  end
end
