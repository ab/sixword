require_relative 'sixword/version'
require_relative 'sixword/words'

module Sixword

  # Parent class for inputs that could plausibly occur at runtime.
  class InputError < ArgumentError; end

  class InvalidParity < InputError; end
  class UnknownWord < InputError; end
  class InvalidWord < InputError; end

  def self.encode(byte_string)
    encode_iter(byte_string).to_a
  end

  def self.encode_iter(byte_string)
    unless block_given?
      return Enumerator.new(self, :encode_iter, byte_string)
    end

    unless byte_string.bytesize % 8 == 0
      raise ArgumentError.new(
        "Must pad bytes to multiple of 8 or use pad_encode")
    end

    byte_string.each_byte.each_slice(8) do |slice|
      encode_64_bits(slice).each do |word|
        yield word
      end
    end
  end

  def self.decode(byte_string)
    raise NotImplementedErrror.new
  end

  def self.hex_encode(hex_string)
    hex_encode_iter(hex_string).to_a
  end

  def self.hex_encode_iter(hex_string)
    unless block_given?
      return Enumerator.new(self, :hex_encode_iter, hex_string)
    end
    int = Integer(hex_string.gsub(/[^a-fA-F0-9]/, ''), 16)
    arr = []

    while int > 0
      arr.unshift (int & 255)
      int >>= 8
    end

    arr.each_slice(8) do |slice|
      encode_64_bits(slice).each do |word|
        yield word
      end
    end
  end

  private
  def self.encode_64_bits(byte_array)
    unless byte_array.length == 8
      raise ArgumentError.new("Must pass an 8-byte array")
    end

    int = byte_array_to_int(byte_array)

    parity_bits = parity_int(int)

    encoded = Array.new(6)

    last_index = ((int & 511) << 2) | parity_bits
    encoded[5] = WORDS.fetch(last_index)
    int >>= 9

    4.downto(0) do |i|
      encoded[i] = WORDS.fetch(int & 2047)
      int >>= 11
    end

    encoded
  end

  def self.decode_6_words(word_array)
    unless word_array.length == 6
      raise ArgumentError.new("Must pass a six-word array")
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

    int
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

  def self.byte_array_to_int(byte_array)
    int = 0
    byte_array.each do |byte|
      int <<= 8
      int |= byte
    end
    int
  end
end
