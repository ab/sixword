require_relative 'sixword/cli'
require_relative 'sixword/hex'
require_relative 'sixword/lib'
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

    unless byte_string
      raise ArgumentError.new("byte_string is falsy")
    end

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

  def self.pad_decode(string_or_words)
    decode(string_or_words, padding_ok: true)
  end
end
