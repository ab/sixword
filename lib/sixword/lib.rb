module Sixword
  module Lib
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

    # Extract the padding from a word, e.g. 'WORD3' => 'WORD', 3
    def self.extract_padding(word)
      unless word[-1] =~ /[1-7]/
        raise ArgumentError.new("Not a valid padded word: #{word.inspect}")
      end

      return word[0...-1], Integer(word[-1])
    end

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

    # Compute parity in a different way. TODO: figure out which is faster
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
    # For example:
    #
    #     >> byte_array_to_int([1, 2])
    #     => 258
    #
    # @param byte_array [Array<Fixnum>]
    #
    # @return Integer
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
    # For example:
    #
    #     >> int_to_byte_array(258)
    #     => [1, 2]
    #
    #     >> int_to_byte_array(258, 3)
    #     => [0, 1, 2]
    #
    # @param int [Integer]
    # @param length [Integer] (nil) Left zero padded size of byte array to
    #   return. If not provided, no leading zeroes will be added.
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
