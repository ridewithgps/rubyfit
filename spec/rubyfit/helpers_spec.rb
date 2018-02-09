require 'spec_helper'
require 'rubyfit/helpers'

describe RubyFit::Helpers do
  include RubyFit::Helpers
  describe "num2bytes" do
    it "returns the little endian byte string for a number" do
      expect(num2bytes(0, 1)).to eq([0x00])
      expect(num2bytes(1, 1)).to eq([0x01])
      expect(num2bytes(256, 2)).to eq([0x01, 0x00])
      expect(num2bytes(2**32-1, 4)).to eq([0xFF, 0xFF, 0xFF, 0xFF])
      expect(num2bytes(2**32, 5)).to eq([0x01, 0x00, 0x00, 0x00, 0x00])

      expect(num2bytes(-1, 1)).to eq([0xFF])
      expect(num2bytes(-1, 4)).to eq([0xFF, 0xFF, 0xFF, 0xFF])
      expect(num2bytes(-128, 1)).to eq([0x80])
      expect(num2bytes(-129, 2)).to eq([0xFF, 0x7F])
    end

    it "it truncates the value when the result is larger than the specified size" do
      expect(num2bytes(0, 1)).to eq([0x00])
      expect(num2bytes(1, 1)).to eq([0x01])
      expect(num2bytes(256, 1)).to eq([0x00])
      expect(num2bytes(2**32-1, 4)).to eq([0xFF, 0xFF, 0xFF, 0xFF])
      expect(num2bytes(2**32, 4)).to eq([0x00, 0x00, 0x00, 0x00])
    end

    it "truncates negative numbers" do
      expect(num2bytes(-129, 1)).to eq([0x7f])
      expect(num2bytes(-(2**31 - 16), 1)).to eq([0xF0])
    end

    it "it pads with 0s when the result is positive and smaller than the specified size" do
      expect(num2bytes(0, 2)).to eq([0x00, 0x00])
      expect(num2bytes(1, 2)).to eq([0x00, 0x01])
      expect(num2bytes(256, 3)).to eq([0x00, 0x01, 0x00])
      expect(num2bytes(2**32-1, 5)).to eq([0x00, 0xFF, 0xFF, 0xFF, 0xFF])
      expect(num2bytes(2**32, 5)).to eq([0x01, 0x00, 0x00, 0x00, 0x00])
    end

    it "it pads with FF when the result is negative and smaller than the specified size" do
      expect(num2bytes(-1, 2)).to eq([0xFF, 0xFF])
      expect(num2bytes(-128, 2)).to eq([0xFF, 0x80])
      expect(num2bytes(-128, 4)).to eq([0xFF, 0xFF, 0xFF, 0x80])
    end
  end

  describe "bytes2num" do
    it "converts a byte array into an unsigned integer" do
      expect(bytes2num([0x00], 1)).to eq(0x00)
      expect(bytes2num([0x01], 1)).to eq(1)
      expect(bytes2num([0xFF], 1)).to eq(255)

      expect(bytes2num([0x00, 0x00], 2)).to eq(0x00)
      expect(bytes2num([0x00, 0xFF], 2)).to eq(255)
      expect(bytes2num([0xFF, 0xFF], 2)).to eq(2**16 - 1)

      expect(bytes2num([0x00, 0x00, 0x00, 0x00], 4)).to eq(0)
      expect(bytes2num([0xFF, 0xFF, 0xFF, 0xFF], 4)).to eq(2**32 - 1)
    end

    it "converts a byte array into a signed integer" do
      expect(bytes2num([0x00], 1, false)).to eq(0x00)
      expect(bytes2num([0x01], 1, false)).to eq(1)
      expect(bytes2num([0xFF], 1, false)).to eq(-1)
      expect(bytes2num([0x80], 1, false)).to eq(-(2**7))

      expect(bytes2num([0x00, 0x00], 2, false)).to eq(0x00)
      expect(bytes2num([0x00, 0xFF], 2, false)).to eq(255)
      expect(bytes2num([0xFF, 0xFF], 2, false)).to eq(-1)
      expect(bytes2num([0x80, 0x00], 2, false)).to eq(-(2**15))

      expect(bytes2num([0x00, 0x00, 0x00, 0x00], 4, false)).to eq(0)
      expect(bytes2num([0x80, 0x00, 0x00, 0x00], 4, false)).to eq(-(2**31))
      expect(bytes2num([0xFF, 0xFF, 0xFF, 0xFF], 4, false)).to eq(-1)
    end
  end

  describe "str2bytes" do
    it "returns a byte array representation of the string" do
      expect(str2bytes("", 1)).to eq([0])
      expect(str2bytes("foo", 4)).to eq(['f'.ord, 'o'.ord, 'o'.ord, 0])
    end

    it "truncates the value when the result is larger than the specified size" do
      expect(str2bytes("foo", 1)).to eq([0])
      expect(str2bytes("foo", 2)).to eq(['f'.ord, 0])
      expect(str2bytes("foo", 4)).to eq(['f'.ord, 'o'.ord, 'o'.ord, 0])
    end

    it "pads the value when the result is smaller than the specified size" do
      expect(str2bytes("", 1)).to eq([0])
      expect(str2bytes("", 2)).to eq([0, 0])
      expect(str2bytes("foo", 8)).to eq(['f'.ord, 'o'.ord, 'o'.ord, 0, 0, 0, 0, 0])
    end
  end
end
