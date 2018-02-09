module RubyFit::Helpers
  # Garmin timestamps start at 12:00:00 01-01-1989, 20 years after the unix epoch
  GARMIN_TIME_OFFSET = 631065600 

  DEGREES_TO_SEMICIRCLES = 2**31 / 180.0

  # Converts a fixnum or bignum into a byte array, optionally
  # truncating or right-filling with 0 to match a certain size
  def num2bytes(num, byte_count, big_endian = true)
    raise ArgumentError.new("num must be an integer") unless num.is_a?(Integer)
    orig_num = num
    # Convert negative numbers to two's complement (1-byte alignment)
    if num < 0
      num = num.abs

      if num > 2 ** (byte_count * 8 - 1)
        STDERR.puts("RubyFit WARNING: Integer underflow for #{orig_num} (#{orig_num.bit_length + 1} bits) when fitting in #{byte_count} bytes (#{byte_count * 8} bits)")
      end

      num = 2 ** (byte_count * 8) - num
    end

    hex = num.to_s(16)
    # pack('H*') assumes the high nybble is first, which reverses nybbles in
    # the most significant byte if it's only one hex char (<= 0xF). Prevent
    # this by prepending a zero if the hex string is an odd length
    hex = "0" + hex if hex.length.odd?
    result = [hex]
      .pack('H*')
      .unpack("C*")

    if result.size > byte_count
      STDERR.puts("RubyFit WARNING: Truncating #{orig_num} (#{orig_num.bit_length} bits) to fit in #{byte_count} bytes (#{byte_count * 8} bits)")
      result = result.last(byte_count)
    elsif result.size < byte_count
      pad_bytes = [0] * (byte_count - result.size)
      result.unshift(*pad_bytes)
    end

    result.reverse! unless big_endian

    result
  end

  def bytes2num(bytes, byte_count, unsigned = true, big_endian = true)
    directive = {
      1 => "C",
      2 => "S",
      4 => "L",
      8 => "Q"
    }[byte_count]
    raise "Unsupported byte count: #{byte_count}" unless directive
    directive << (big_endian ? ">" : "<") if byte_count > 1
    directive.downcase! unless unsigned
    bytes.pack("C*").unpack(directive).first
  end

  # Converts an ASCII string into a byte array, truncating or right-filling
  # with 0 to match byte_count
  def str2bytes(str, byte_count)
    str
      .unpack("C#{byte_count - 1}") # Convert to n-1 bytes
      .map{|v| v || 0} + [0] # Convert nils to 0 and add null terminator
  end

  # Converts a byte array to a string. Omits the last character of the byte
  # array from the result if it is 0
  def bytes2str(bytes)
    bytes = bytes[0...-1] if bytes.last == 0
    bytes.pack("C*")
  end

  # Generates strings of hex bytes (for debugging)
  def bytes2hex(bytes)
    bytes
      .map{|b| "0x#{b.to_s(16).ljust(2, "0")}"}
      .each_slice(8)
      .map{ |s| s.join(", ") }
  end

  def unix2fit_timestamp(timestamp)
    timestamp - GARMIN_TIME_OFFSET
  end

  def fit2unix_timestamp(timestamp)
    timestamp + GARMIN_TIME_OFFSET
  end


  def deg2semicircles(degrees)
    (degrees * DEGREES_TO_SEMICIRCLES).truncate
  end

  def semicircles2deg(degrees)
    result = degrees / DEGREES_TO_SEMICIRCLES
    result -= 360.0 if result > 180.0
    result += 360.0 if result < -180.0
    result
  end

  def make_message_header(opts = {})
    result = 0
    result |= (1 << 6) if opts[:definition]
    result |= (opts[:local_number] || 0) & 0xF
    result
  end
end
