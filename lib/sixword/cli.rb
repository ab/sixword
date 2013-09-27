module Sixword
  class CLI
    class CLIError < StandardError; end

    attr_reader :filename, :options, :stream, :mode

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

    def pad?
      options.fetch(:pad)
    end

    def encoding?
      mode == :encode
    end

    def hex_style
      options[:hex_style]
    end

    def print_hex(data, chunk_index, cols=80)
      case hex_style
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

      arr = []
      read_input_by_6_words do |arr|
        yield Sixword.decode(arr, padding_ok: pad?)
      end
    end

    def do_encode!
      process_encode_input do |chunk|
        Sixword.encode_iter(chunk, words_per_slice:6, pad:pad?) do |encoded|
          yield encoded
        end
      end
    end

    def process_encode_input
      unless block_given?
        raise ArgumentError.new("block is required")
      end

      if hex_style
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
      block_size = 2048
      word_arr = []

      while true
        buf = stream.read(block_size)
        if buf.nil?
          break #EOF
        end

        buf.scan(/\S+/) do |word|
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
      else
        raise CLIError.new("unknown hex style: #{hex_style.inspect}")
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
