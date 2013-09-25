require_relative 'sixword/version'
require_relative 'sixword/words'

module Sixword

  # Parent class for inputs that could plausibly occur at runtime.
  class InputError < ArgumentError; end

  class InvalidParity < InputError; end
  class UnknownWord < InputError; end
  class InvalidWord < InputError; end

  def self.encode(byte_string)
    encode_to_a(byte_string)
  end

  def self.pad_encode(byte_string)
    pad_encode_to_a(byte_string)
  end

  def self.encode_to_sentences(byte_string)
    encode_iter(byte_string, words_per_slice:6).to_a
  end

  def self.encode_to_s(byte_string)
    encode(byte_string).join(' ')
  end

  def self.encode_to_a(byte_string)
    encode_iter(byte_string).to_a
  end

  def self.pad_encode_to_a(byte_string)
    encode_iter(byte_string, words_per_slice:1, pad:true).to_a
  end

  def self.pad_encode_to_sentences(byte_string)
    encode_iter(byte_string, words_per_slice:6, pad:true).to_a
  end

  def self.encode_iter(byte_string, options={})
    options = {words_per_slice: 1, pad: false}.merge(options)
    words_per_slice = options.fetch(:words_per_slice)
    pad = options.fetch(:pad)

    unless block_given?
      return Enumerator.new(self, :encode_iter, byte_string, options)
    end

    if !pad && byte_string.bytesize % 8 != 0
      raise InputError.new(
        "Must pad bytes to multiple of 8 or use pad_encode")
    end

    unless (1..6).include?(words_per_slice)
      raise ArgumentError.new("words_per_slice must be in 1..6")
    end

    byte_string.each_byte.each_slice(8) do |slice|
      # figure out whether we need padding
      padding = nil
      if pad && slice.length < 8
        padding = 8 - slice.length
        padding.times do
          slice << 0
        end
      end

      # encode the data
      encoded = encode_64_bits(slice)

      # add padding information as needed
      if padding
        encoded[-1] << padding.to_s
      end

      encoded.each_slice(words_per_slice) do |encoded_slice|
        yield encoded_slice.join(' ')
      end
    end
  end

  def self.decode(string_or_words, options={})
    options = {padding_ok: false}.merge(options)
    padding_ok = options.fetch(:padding_ok)

    if string_or_words.is_a?(String)
      words = string_or_words.split
    else
      words = string_or_words
    end

    unless words.length % 6 == 0
      raise InputError.new('Must enter a multiple of 6 words')
    end

    bstring = ''

    words.each_slice(6) do |slice|
      bstring << decode_6_words_to_bstring(slice, padding_ok)
    end

    bstring
  end

  def self.pad_decode(string_or_words)
    decode(string_or_words, padding_ok: true)
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

    int
  end

  # Extract the padding from a word, e.g. 'WORD3' => 'WORD', 3
  def self.extract_padding(word)
    unless word[-1] =~ /[1-7]/
      raise ArgumentError.new("Not a valid word with padding: #{word.inspect}")
    end

    return word[0...-1], Integer(word[-1])
  end

  def self.decode_6_words_to_bstring(word_array, padding_ok)
    int_to_byte_array(decode_6_words(word_array, padding_ok)).map(&:chr).join
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

  def self.int_to_byte_array(int)
    unless int >= 0
      raise ArgumentError.new("Not sure what to do with negative numbers")
    end

    arr = []

    while int > 0
      arr << (int & 255)
      int >>= 8
    end

    arr.reverse!

    arr
  end
end
