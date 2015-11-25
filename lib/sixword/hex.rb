module Sixword
  # Various hexadecimal string encoding and decoding functions
  module Hex
    HexValid = /\A[a-fA-F0-9]+\z/
    HexStrip = /[\s:.-]+/

    # Return whether string is entirely hexadecimal.
    # @param string [String]
    # @return [Boolean]
    # @see [HexValid]
    #
    def self.valid_hex?(string)
      !!(string =~ HexValid)
    end

    # Return whether single character string is one of the fill characters that
    # are OK to strip from a hexadecimal string.
    # @param char [String] String of length == 1
    # @return [Boolean]
    # @see [HexStrip]
    #
    def self.strip_char?(char)
      unless char.length == 1
        raise ArgumentError.new("Must pass single character string")
      end
      !!(char =~ HexStrip)
    end

    # Encode a byte string as hexadecimal.
    #
    # @param bytes [String]
    # @return [String] hexadecimal string
    #
    def self.encode(bytes)
      bytes.unpack('H*').fetch(0)
    end

    # Encode a byte string as hexadecimal, returning it in slices joined by a
    # delimiter. This is useful for generating colon or space separated strings
    # like those commonly used in fingerprints.
    #
    # @param bytes [String]
    # @param slice [Integer]
    # @param delimiter [String]
    #
    # @return [String]
    #
    # @example
    #   >> encode_slice("9T]B\xF0\x039\xFF", 2, ':')
    #   => "39:54:5d:42:f0:03:39:ff"
    #
    def self.encode_slice(bytes, slice, delimiter)
      encode(bytes).each_char.each_slice(slice).map(&:join).join(delimiter)
    end

    # Encode a byte string as a GPG style fingerprint: uppercase in slices of 4
    # separated by spaces.
    #
    # @param bytes [String]
    # @return [String]
    #
    # @example
    #   >> encode_fingerprint("9T]B\xF0\x039\xFF")
    #   => "3954 5D42 F003 39FF"
    #
    def self.encode_fingerprint(bytes)
      encode_slice(bytes, 4, ' ').upcase
    end

    # Encode a byte string in hex with colons: lowercase in slices of 2
    # separated by colons.
    #
    # @param bytes [String]
    # @return [String]
    #
    # @example
    #   >> encode_colons("9T]B\xF0\x039\xFF")
    #   => "39:54:5d:42:f0:03:39:ff"
    #
    #
    def self.encode_colons(bytes)
      encode_slice(bytes, 2, ':')
    end

    # Decode a hexadecimal string to a byte string.
    #
    # @param hex_string [String]
    # @param strip_chars [Boolean] Whether to accept and strip whitespace and
    #   other delimiters (see {HexStrip})
    # @return [String]
    #
    # @raise ArgumentError on invalid hex input
    #
    def self.decode(hex_string, strip_chars=true)
      if strip_chars
        hex_string = hex_string.gsub(HexStrip, '')
      end

      unless valid_hex?(hex_string)
        raise ArgumentError.new("Invalid value for hex: #{hex_string.inspect}")
      end

      unless hex_string.length.even?
        raise ArgumentError.new("Odd length hex: #{hex_string.inspect}")
      end

      [hex_string].pack('H*')
    end
  end
end
