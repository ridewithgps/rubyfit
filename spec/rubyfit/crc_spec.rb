require 'spec_helper.rb'

describe RubyFit::CRC do
  describe ".update_crc" do
    let(:data) { [0, 1, 2, 4, 8, 16, 32, 64, 128].pack("C*") }
    it "generates a CRC from a string with a single byte" do
      expect(described_class.update_crc(0, "a")).to eq(0xE8C1) # Calculated by hand using the algorithm
    end

    it "generates a CRC from a string of bytes" do
      expect(described_class.update_crc(0, data)).to eq(0x2337)
    end

    it "takes an initialization value and updates it" do
      expect(described_class.update_crc(30715, data)).to eq(0xD506)
    end
  end
end

