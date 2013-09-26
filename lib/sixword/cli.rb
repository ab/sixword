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

    def print_hex(data, first_chunk)
      case hex_style
      when 'lower', 'lowercase'
        # encode to lowercase hex with no newlines
        print Sixword::Hex.encode(data)
      when 'finger', 'fingerprint'
        # encode to GPG fingerprint like hex with newlines
        print "\n" unless first_chunk
        print Sixword::Hex.encode_fingerprint(data)
      when 'colon', 'colons'
        # encode to SSL/SSH fingerprint like hex with colons
        print ':' unless first_chunk
        print Sixword::Hex.encode_colons(data)
      end
    end

    def run!
      if encoding?
        do_encode! do |encoded|
          puts encoded
        end
      else
        first_chunk = true
        do_decode! do |decoded|
          if hex_style
            print_hex(decoded, first_chunk)
            first_chunk = false if first_chunk
          else
            print decoded
          end
        end
        # trailing newline
        puts
      end
    end

    private

    def do_encode!
      process_input do |chunk|
        Sixword.encode_iter(chunk, words_per_slice:6, pad:pad?) do |encoded|
          yield encoded
        end
      end
    end

    def process_input
      unless block_given?
        raise ArgumentError.new("must pass block")
      end

      if encoding? && hex_style
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
        while true
          # yield data 8 bytes at a time until EOF
          buf = stream.read(8)
          yield buf

          if buf.length < 8
            # EOF
            break
          end
        end
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
