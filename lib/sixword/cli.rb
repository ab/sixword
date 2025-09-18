require 'base64'

module Sixword

  # The Sixword::CLI class implements all of the complex processing needed for
  # the sixword Command Line Interface.
  class CLI

    # Exception for certain input validation errors
    class CLIError < StandardError; end

    # @return [String] Input filename
    attr_reader :filename

    # @return [Hash] Options hash
    attr_reader :options

    # @return [File, IO] Stream opened from #filename
    attr_reader :stream

    # @return [:encode, :decode]
    attr_reader :mode

    # Create a Sixword CLI to operate on filename with options
    #
    # @param filename [String] Input file name (or '-' for stdin)
    # @param options [Hash]
    #
    # @option options [:encode, :decode] :mode (:encode)
    # @option options [Boolean] :pad (false)
    # @option options [String] :style
    # @option options [String] :hex_style Alias of :style
    # @option options [Integer] :line_width (1) In encode mode, the number of
    #   sentences to output per line.
    #
    def initialize(filename, options)
      @filename = filename
      @options = {mode: :encode, pad: false}.merge(options)

      if filename == '-'
        # dup stdin and put it into binary mode
        @stream = $stdin.dup
        @stream.binmode
      else
        # read in binary mode even on unix so ruby yields binary encoding
        @stream = File.open(filename, 'rb')
      end


      @mode = @options.fetch(:mode)
      unless [:encode, :decode].include?(mode)
        raise ArgumentError.new("Invalid mode: #{mode.inspect}")
      end
    end

    # Return the value of the :pad option.
    # @return [Boolean]
    def pad?
      options.fetch(:pad)
    end

    # Return true if we are in encoding mode, false otherwise (decoding).
    # @return [Boolean]
    def encoding?
      mode == :encode
    end

    # Return the value of the :style option.
    # @return [String, nil]
    def style
      options[:style] || options[:hex_style]
    end

    # Return the value of the :hex_style option.
    # @deprecated Use {#style} instead.
    # @return [String, nil]
    def hex_style
      options[:style] || options[:hex_style]
    end

    # Format data as hex in various styles.
    def print_hex(data, chunk_index, cols=80)
      case hex_style
      when 'b64', 'base64'
        # encode as base64
        print Base64.strict_encode64(data)
      when 'lower', 'lowercase'
        # encode to lowercase hex with no newlines
        print Sixword::Hex.encode(data)
      when 'finger', 'fingerprint'
        # encode to GPG fingerprint like hex with newlines
        newlines_every = cols / 5
        if chunk_index != 0
          if chunk_index % newlines_every == 0
            print "\n"
          else
            print ' '
          end
        end
        print Sixword::Hex.encode_fingerprint(data)
      when 'colon', 'colons'
        # encode to SSL/SSH fingerprint like hex with colons
        print ':' unless chunk_index == 0
        print Sixword::Hex.encode_colons(data)
      end
    end

    # Run the encoding/decoding operation, printing the result to stdout.
    def run!
      if encoding?
        do_encode! do |encoded|
          puts encoded
        end
      else
        chunk_index = 0
        do_decode! do |decoded|
          if hex_style
            print_hex(decoded, chunk_index)
            chunk_index += 1
          else
            print decoded
          end
        end

        # add trailing newline for hex output
        puts if hex_style
      end
    end

    private

    def do_decode!
      unless block_given?
        raise ArgumentError.new("block is required")
      end

      # base64 decoding must happen in one shot to avoid inserting unnecessary
      # padding in the middle
      if hex_style == 'base64' || hex_style == 'b64'
        yield Sixword.decode(stream.read, padding_ok: pad?)
      else
        # chunk input in 6-word sentences
        read_input_by_6_words do |arr|
          yield Sixword.decode(arr, padding_ok: pad?)
        end
      end
    end

    def do_encode!
      sentences_per_line = options.fetch(:line_width, 1)
      if sentences_per_line <= 0
        sentences_per_line = 1 << 32
      end

      sentences = []

      process_encode_input do |chunk|
        Sixword.encode_iter(chunk, words_per_slice:6, pad:pad?) do |encoded|
          sentences << encoded

          # yield sentences once we reach sentences_per_line of them
          if sentences.length >= sentences_per_line
            yield sentences.join(' ')
            sentences.clear
          end
        end
      end

      # yield any leftover sentences
      unless sentences.empty?
        yield sentences.join(' ')
      end
    end

    def process_encode_input
      unless block_given?
        raise ArgumentError.new("block is required")
      end

      if hex_style == "base64" || hex_style == "b64"
        # Base64 needs 10.66 bytes to encode 8 binary bytes
        # so we can't neatly chunk input like we can with hex.
        # Instead just read the whole thing and yield in chunks of 8 bytes.
        buf = Base64.decode64(stream.read)
        buf.each_char.each_slice(8) do |chunk|
          yield chunk.join
        end

      elsif hex_style
        # yield data in chunks from accumulate_hex_input until EOF
        accumulate_hex_input do |hex|
          begin
            data = Sixword::Hex.decode(hex)
          rescue ArgumentError => err
            # expose hex decoding failures to user
            raise CLIError.new(err.message)
          else
            yield data
          end
        end

      else
        # yield data 8 bytes at a time until EOF
        while true
          buf = stream.read(8)
          if buf
            yield buf
          else
            # EOF
            break
          end
        end
      end
    end

    # Yield data 6 words at a time until EOF
    def read_input_by_6_words
      word_arr = []

      while true
        line = stream.gets
        if line.nil?
          break # EOF
        end

        line.scan(/\S+/) do |word|
          word_arr << word

          # return the array if we have accumulated 6 words
          if word_arr.length == 6
            yield word_arr
            word_arr.clear
          end
        end
      end

      # yield whatever we have left, if anything
      if !word_arr.empty?
        yield word_arr
      end
    end

    def accumulate_hex_input
      unless block_given?
        raise ArgumentError.new("must pass block")
      end

      # these are actually treated the same at the moment
      case hex_style
      when 'lower', 'lowercase'
      when 'finger', 'fingerprint'
      when 'colon', 'colons'
      else
        raise CLIError.new("unknown style: #{hex_style.inspect}")
      end

      while true
        buf = ''

        # try to accumulate 8 bytes (16 chars) before yielding the hex
        while buf.length < 16
          char = stream.getc
          if char.nil?
            # EOF, so yield whatever we have if it's non-empty
            yield buf unless buf.empty?
            return
          end

          if Sixword::Hex.valid_hex?(char)
            buf << char
            next
          elsif Sixword::Hex.strip_char?(char)
            next
          end

          raise CLIError.new("invalid hex character: #{char.inspect}")
        end

        yield buf
      end
    end
  end
end
