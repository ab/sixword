module Sixword
  module Hex
    HexValid = /\A[a-fA-F0-9]+\z/
    HexStrip = /[\s:.-]+/

    def self.valid_hex?(string)
      !!(string =~ HexValid)
    end

    def self.strip_char?(char)
      unless char.length == 1
        raise ArgumentError.new("Must pass single character string")
      end
      !!(char =~ HexStrip)
    end

    def self.encode(bytes)
      bytes.unpack('H*').fetch(0)
    end

    def self.encode_slice(bytes, slice, delimiter)
      encode_hex(bytes).each_char.each_slice(slice).map(&:join).join(delimiter)
    end

    def self.encode_fingerprint(bytes)
      encode_hex_slice(bytes, 4, ' ').upcase
    end

    def self.encode_colons(bytes)
      encode_hex_slice(bytes, 2, ':')
    end

    def self.decode(hex_string, strip_chars=true)
      if strip_chars
        hex_string = hex_string.gsub(HexStrip, '')
      end

      unless valid_hex?(hex_string)
        raise ArgumentError.new("Invalid value for hex: #{hex_string.inspect}")
      end

      unless hex_string.length % 2 == 0
        raise ArgumentError.new("Odd length hex: #{hex_string.inspect}")
      end

      [hex_string].pack('H*')
    end
  end
end
