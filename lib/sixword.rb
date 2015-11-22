require_relative 'sixword/cli'
require_relative 'sixword/hex'
require_relative 'sixword/lib'
require_relative 'sixword/version'
require_relative 'sixword/words'

# Sixword, a binary encoder using the 6-word scheme from S/key standardized by
# RFC 2289, RFC 1760, and RFC 1751.
module Sixword

  # Parent class for inputs that could plausibly occur at runtime.
  class InputError < ArgumentError; end

  class InvalidParity < InputError; end
  class UnknownWord < InputError; end
  class InvalidWord < InputError; end

  # Encode a string of bytes in six-word encoding. If you want to use the
  # custom padding scheme for inputs that are not a multiple of 8 in length,
  # use Sixword.pad_encode instead.
  #
  # @param byte_string [String] Length must be a multiple of 8
  # @return [Array<String>] an array of string words
  #
  # @raise Sixword::InputError
  #
  # @see Sixword.encode_iter
  #
  # @example
  #   >> Sixword.encode('Hi world')
  #   => ["ACRE", "ADEN", "INN", "SLID", "MAD", "PAP"]
  #
  def self.encode(byte_string)
    encode_iter(byte_string).to_a
  end

  # Encode a string of bytes in six-word encoding, using the custom padding
  # scheme established by this library. The output will be identical to
  # Sixword.encode for strings that are a multiple of 8 in length.
  #
  # @param byte_string [String] A string of any length
  # @return [Array<String>] an array of string words
  #
  # @see Sixword.encode_iter
  #
  # @example
  #   >> Sixword.encode('Hi wor')
  #   => ["ACRE", "ADEN", "INN", "SLID", "MAD", "PAP"]
  #
  def self.pad_encode(byte_string)
    encode_iter(byte_string, words_per_slice:1, pad:true).to_a
  end

  # aliases for clarity on what the default encode(), pad_encode() return
  class << self
    alias_method :encode_to_a, :encode
    alias_method :pad_encode_to_a, :pad_encode
  end

  # Like Sixword.encode, but return six words at a time (a complete block).
  #
  # @param byte_string [String] Length must be a multiple of 8
  # @return [Array<String>] an array of 6-word string sentences
  #
  # @raise Sixword::InputError
  #
  # @example
  #   Sixword.encode_to_sentences('Hi world' * 2)
  #   => ["ACRE ADEN INN SLID MAD PAP",
  #       "ACRE ADEN INN SLID MAD PAP"]
  #
  # @see Sixword.encode
  #
  def self.encode_to_sentences(byte_string)
    encode_iter(byte_string, words_per_slice:6).to_a
  end

  # Like Sixword.encode, but return a single string.
  #
  # @param byte_string [String] Length must be a multiple of 8
  # @return [String] a string of words separated by spaces
  #
  # @raise Sixword::InputError
  #
  # @example
  #   Sixword.encode_to_s('Hi world' * 2)
  #   => "ACRE ADEN INN SLID MAD PAP ACRE ADEN INN SLID MAD PAP"
  #
  # @see Sixword.encode
  #
  def self.encode_to_s(byte_string)
    encode(byte_string).join(' ')
  end

  # Like Sixword.encode_to_sentences, but allow variable length input.
  #
  # @param byte_string [String] A string of any length
  # @return [Array<String>] an array of 6-word string sentences
  #
  # @example
  #   >> Sixword.pad_encode_to_sentences('Hi worl' * 2)
  #   => ["ACRE ADEN INN SLID MAD LEW", "CODY AS SIGH SUIT MUDD ABE2"]
  #
  def self.pad_encode_to_sentences(byte_string)
    encode_iter(byte_string, words_per_slice:6, pad:true).to_a
  end

  # Like Sixword.encode_to_s, but allow variable length input.
  #
  # @param byte_string [String] A string of any length
  # @return [String] a string of words separated by spaces
  #
  # @example
  #   >> Sixword.pad_encode_to_s('Hi worl' * 2)
  #   => "ACRE ADEN INN SLID MAD LEW CODY AS SIGH SUIT MUDD ABE2"
  #
  def self.pad_encode_to_s(byte_string)
    pad_encode(byte_string).join(' ')
  end

  # Encode a string of bytes in six-word encoding (full API). This is the
  # relatively low level method that supports all the major options. See the
  # various other top-level methods for convenience helpers.
  #
  # @param byte_string [String] A byte string to encode
  # @param options [Hash]
  #
  # @option options [Boolean] :pad (false) Whether to use the custom padding
  #   scheme established by this library. If false, then byte_string length
  #   must be a multiple of 8.
  # @option options [Integer] :words_per_slice (1) The number of words to
  #   yield together in each iteration. By default, yield only a single word at
  #   a time. You can yield up to 6 words together, which will be joined by a
  #   space ` ` character.
  #
  # @yield [String] A String word (or String of space separated words, if
  #   :words_per_slice is given)
  #
  # @return [Enumerator, nil] If no block is given, return an Enumerator
  #
  # @raise Sixword::InputError on incorrectly padded inputs
  # @raise ArgumentError on bad argument types
  #
  def self.encode_iter(byte_string, options={})
    options = {words_per_slice: 1, pad: false}.merge(options)
    words_per_slice = options.fetch(:words_per_slice)
    pad = options.fetch(:pad)

    unless byte_string
      raise ArgumentError.new("byte_string is falsy")
    end

    unless block_given?
      return to_enum(__method__, byte_string, options)
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
      encoded = Lib.encode_64_bits(slice)

      # add padding information as needed
      if padding
        encoded[-1] << padding.to_s
      end

      encoded.each_slice(words_per_slice) do |encoded_slice|
        yield encoded_slice.join(' ')
      end
    end
  end

  # Decode a six-word encoded string or string array.
  #
  # @param string_or_words [String, Array<String>] Either a String containing
  #   whitespace separated words or an Array of String words
  # @param options [Hash]
  #
  # @option options [Boolean] :padding_ok (false) Whether to accept the custom
  #   padding format established by this library
  #
  # @return [String] A binary string of bytes
  #
  # @raise InputError if the input is malformed or invalid in various ways
  #
  # @example
  #   >> Sixword.decode("ACRE ADEN INN SLID MAD PAP")
  #   => "Hi world"
  #
  # @example
  #   Sixword.decode(%w{ACRE ADEN INN SLID MAD PAP})
  #   => "Hi world"
  #
  # @example
  #   Sixword.decode([])
  #   => ""
  #
  # @example
  #   Sixword.decode("COAT ACHE A A A ACT6", padding_ok: true)
  #   => "hi"
  #
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
      bstring << Lib.decode_6_words_to_bstring(slice, padding_ok)
    end

    bstring
  end

  # Like Sixword.decode, but allow input to contain custom padding scheme.
  #
  # @see Sixword.decode
  #
  # @param string_or_words [String, Array<String>] Either a String containing
  #   whitespace separated words or an Array of String words
  #
  # @return [String] A binary string of bytes
  #
  # @raise InputError if the input is malformed or invalid in various ways
  #
  # @example
  #   Sixword.decode("COAT ACHE A A A ACT6", padding_ok: true)
  #   => "hi"
  #
  def self.pad_decode(string_or_words)
    decode(string_or_words, padding_ok: true)
  end
end
