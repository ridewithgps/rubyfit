require "rubyfit/helpers"

class RubyFit::Type
  attr_reader *%i(fit_id byte_count default_bytes)

  def initialize(opts = {})
    @val2bytes = opts[:val2bytes]
    @bytes2val = opts[:bytes2val]
    @rb2fit = opts[:rb2fit]
    @fit2rb = opts[:fit2rb]
    @default_bytes = opts[:default_bytes]
    @byte_count = opts[:byte_count]
    @fit_id = opts[:fit_id]
  end

  def val2bytes(val)
    result = val
    result = @rb2fit.call(result, self) if @rb2fit
    result = @val2bytes.call(result, self)
    result
  end

  def bytes2val(bytes)
    result = bytes
    result = @bytes2val.call(result, self)
    result = @fit2rb.call(result, self) if @fit2rb
    result
  end

  class << self
    include RubyFit::Helpers

    def integer(opts = {})
      unsigned = opts.delete(:unsigned)
      default = opts[:default]

      # Default (invalid) value for integers is the maximum positive value
      # given the bit length and whether the data is signed/unsigned
      unless default
        bit_count = opts[:byte_count] * 8
        bit_count -= 1 unless unsigned
        default = 2**bit_count - 1
      end

      new({
        default_bytes: num2bytes(default, opts[:byte_count]),
        val2bytes: ->(val, type) { num2bytes(val, type.byte_count) },
        bytes2val: ->(bytes, type) { bytes2num(bytes, type.byte_count, unsigned) },
      }.merge(opts))
    end

    # Base Types #
    
    def enum(opts = {})
      uint8(fit_id: 0x00)
    end

    def string(byte_count, opts = {})
      new({
        fit_id: 0x07,
        byte_count: byte_count,
        default_bytes: [0x00] * byte_count,
        val2bytes: ->(val, type) { str2bytes(val, type.byte_count) },
        bytes2val: ->(bytes, type) { bytes2str(bytes) },
      }.merge(opts))
    end

    def byte(byte_count, opts = {})
      new({
        fit_id: 0x0D,
        default_bytes: [0xFF] * length,
        val2bytes: ->(val) { val },
        bytes2val: ->(bytes) { bytes },
      }.merge(opts))
    end

    def sint8(opts = {})
      integer({unsigned: false, byte_count: 1, fit_id: 0x01}.merge(opts))
    end

    def uint8(opts = {})
      integer({unsigned: true, byte_count: 1, fit_id: 0x02}.merge(opts))
    end

    def sint16(opts = {})
      integer({unsigned: false, byte_count: 2, fit_id: 0x83}.merge(opts))
    end

    def uint16(opts = {})
      integer({unsigned: true, byte_count: 2, fit_id: 0x84}.merge(opts))
    end

    def sint32(opts = {})
      integer({unsigned: false, byte_count: 4, fit_id: 0x85}.merge(opts))
    end

    def uint32(opts = {})
      integer({unsigned: true, byte_count: 4, fit_id: 0x86}.merge(opts))
    end

    def sint64(opts = {})
      integer({unsigned: false, byte_count: 8, fit_id: 0x8E}.merge(opts))
    end

    def uint64(opts = {})
      integer({unsigned: true, byte_count: 8, fit_id: 0x8F}.merge(opts))
    end

    def uint8z(opts = {})
      integer({unsigned: true, default: 0, byte_count: 1, fit_id: 0x0A}.merge(opts))
    end

    def uint16z(opts = {})
      integer({unsigned: true, default: 0, byte_count: 2, fit_id: 0x8B}.merge(opts))
    end

    def uint32z(opts = {})
      integer({unsigned: true, default: 0, byte_count: 4, fit_id: 0x8C}.merge(opts))
    end

    def uint64z(opts = {})
      integer({unsigned: true, default: 0, byte_count: 8, fit_id: 0x90}.merge(opts))
    end

    # Derived types
    
    def timestamp
      uint32({
        rb2fit: ->(val, type) { unix2fit_timestamp(val) },
        fit2rb: ->(val, type) { fit2unix_timestamp(val) }
      })
    end

    def semicircles
      sint32({
        rb2fit: ->(val, type) { deg2semicircles(val) },
        fit2rb: ->(val, type) { semicircles2deg(val) }
      })
    end

    def centimeters
      uint32({
        rb2fit: ->(val, type) { (val * 100).truncate },
        fit2rb: ->(val, type) { val / 100.0 }
      })
    end

    def altitude
      uint16({
        rb2fit: ->(val, type) { (val + 500).truncate },
        fit2rb: ->(val, type) { val - 500 }
      })
    end

    def duration
      uint32({
        rb2fit: ->(val, type) { (val * 1000).truncate },
        fit2rb: ->(val, type) { val / 1000.0 }
      })
    end
  end
end
