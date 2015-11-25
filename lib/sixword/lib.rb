module Sixword
  module Lib
    # Encode an array of 8 bytes as an array of 6 words.
    #
    # @param byte_array [Array<Fixnum>] An array of length 8 containing
    #   integers in 0..255
    #
    # @return [Array<String>] An array of length 6 containing String words from
    #   {Sixword::WORDS}
    #
    # @example
    #   >> Sixword::Lib.encode_64_bits([0] * 8)
    #   => ["A", "A", "A", "A", "A", "A"]
    #
    # @example
    #   >> Sixword::Lib.encode_64_bits([0xff] * 8)
    #   => ["YOKE", "YOKE", "YOKE", "YOKE", "YOKE", "YEAR"]
    #
    def self.encode_64_bits(byte_array)
      unless byte_array.length == 8
        raise ArgumentError.new("Must pass an 8-byte array")
      end

      int = byte_array_to_int(byte_array)

      parity_bits = parity_int(int)

      encoded = Array.new(6)

      last_index = ((int & 511) << 2) | parity_bits
      encoded[5] = WORDS.fetch(last_index).dup
      int >>= 9

      4.downto(0) do |i|
        encoded[i] = WORDS.fetch(int & 2047).dup
        int >>= 11
      end

      encoded
    end

    # Decode an array of 6 words into a 64-bit integer (representing 8 bytes).
    #
    # @param word_array [Array<String>] A 6 element array of String words
    # @param padding_ok [Boolean]
    #
    # @return [Array(Integer, Integer)] a 64-bit integer (the data) and the
    # length of the byte array that it represents (will always be 8 unless
    # padding_ok)
    #
    # @example
    #   >> Sixword::Lib.decode_6_words(%w{COAT ACHE A A A ACT6}, true)
    #   => [26729, 2]
    #
    #   >> Sixword::Lib.decode_6_words(%w{ACRE ADEN INN SLID MAD PAP}, false)
    #   => [5217737340628397156, 8]
    #
    def self.decode_6_words(word_array, padding_ok)
      unless word_array.length == 6
        raise ArgumentError.new("Must pass a six-word array")
      end

      bits_array = []

      padding = 0

      # extract padding, if any
      if padding_ok && word_array[-1][-1] =~ /[1-7]/
        word, padding = extract_padding(word_array[-1])
        word_array[-1] = word
      end

      bits_array = word_array.map {|w| word_to_bits(w) }

      bits_array.each do |bits|
        if bits >= 2048 || bits < 0
          raise RuntimeError.new("Somehow got bits of #{bits.inspect}")
        end
      end

      int = 0
      (0..4).each do |i|
        int <<= 11
        int += bits_array.fetch(i)
      end

      # slice out parity from last word
      parity = bits_array.fetch(5) & 0b11
      int <<= 9
      int += bits_array.fetch(5) >> 2

      # check parity
      unless parity_int(int) == parity
        raise InvalidParity.new("Parity bits do not match")
      end

      # omit padding bits, if any
      int >>= padding * 8

      [int, 8 - padding]
    end

    # Extract the numeric padding from a word.
    #
    # @param word [String]
    # @return [Array(String, Integer)] The String word, the Integer padding
    #
    # @example
    #   >> Sixword::Lib.extract_padding("WORD3")
    #   => ["WORD", 3]
    #
    def self.extract_padding(word)
      unless word[-1] =~ /[1-7]/
        raise ArgumentError.new("Not a valid padded word: #{word.inspect}")
      end

      return word[0...-1], Integer(word[-1])
    end

    # Decode an array of 6 words into a String of bytes.
    #
    # @param word_array [Array<String>] A 6 element array of String words
    # @param padding_ok [Boolean]
    #
    # @return [String]
    #
    # @see Sixword.decode_6_words
    # @see Sixword.int_to_byte_array
    #
    # @example
    #   >> Lib.decode_6_words_to_bstring(%w{COAT ACHE A A A ACT6}, true)
    #   => "hi"
    #
    #   >> Lib.decode_6_words_to_bstring(%w{ACRE ADEN INN SLID MAD PAP}, false)
    #   => "Hi world"
    #
    def self.decode_6_words_to_bstring(word_array, padding_ok)
      int_to_byte_array(*decode_6_words(word_array, padding_ok)).
        map(&:chr).join
    end

    def self.word_to_bits(word)
      word = word.upcase
      return WORDS_HASH.fetch(word)
    rescue KeyError
      if (1..4).include?(word.length)
        raise UnknownWord.new("Unknown word: #{word.inspect}")
      else
        raise InvalidWord.new("Word must be 1-4 chars, not #{word.inspect}")
      end
    end

    # Compute two-bit parity on a byte array by summing each pair of bits.
    # TODO: figure out which is faster
    #
    # @param byte_array [Array<Fixnum>]
    # @return [Fixnum] An integer 0..3
    #
    # @see parity_int
    #
    def self.parity_array(byte_array)

      # sum pairs of bits through the whole array
      parity = 0
      byte_array.each do |byte|
        while byte > 0
          parity += byte & 0b11
          byte >>= 2
        end
      end

      # return the least significant two bits
      parity & 0b11
    end

    # Compute two-bit parity on a 64-bit integer representing an 8-byte array
    # by summing each pair of bits.
    # TODO: figure out which is faster
    #
    # @param int [Integer] A 64-bit integer representing 8 bytes
    # @return [Fixnum] An integer 0..3
    #
    # @see parity_array
    #
    def self.parity_int(int)
      parity = 0
      while int > 0
        parity += int & 0b11
        int >>= 2
      end

      parity & 0b11
    end

    # Given an array of bytes, pack them into a single Integer.
    #
    # @example
    #
    #     >> byte_array_to_int([1, 2])
    #     => 258
    #
    # @param byte_array [Array<Fixnum>]
    #
    # @return [Integer]
    #
    def self.byte_array_to_int(byte_array)
      int = 0
      byte_array.each do |byte|
        int <<= 8
        int |= byte
      end
      int
    end

    # Given an Integer, unpack it into an array of bytes.
    #
    # @example
    #     >> int_to_byte_array(258)
    #     => [1, 2]
    #
    # @example
    #     >> int_to_byte_array(258, 3)
    #     => [0, 1, 2]
    #
    # @param int [Integer]
    # @param length [Integer] Left zero padded size of byte array to return. If
    #   not provided, no leading zeroes will be added.
    #
    # @return [Array<Fixnum>]
    #
    def self.int_to_byte_array(int, length=nil)
      unless int >= 0
        raise ArgumentError.new("Not sure what to do with negative numbers")
      end

      arr = []

      while int > 0
        arr << (int & 255)
        int >>= 8
      end

      # pad to appropriate length with leading zeroes
      if length
        raise ArgumentError.new("Cannot pad to length < 0") if length < 0

        while arr.length < length
          arr << 0
        end
      end

      arr.reverse!

      arr
    end
  end
end
