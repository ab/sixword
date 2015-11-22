# coding: binary
require_relative 'rspec_helper'

describe Sixword do
  it 'should encode RFC hex vectors correctly' do
    Sixword::TestVectors::HexTests.each do |_section, tests|
      tests.each do |hex, sentence|
        words = sentence.split
        byte_string = Sixword::Hex.decode(hex)
        debug_puts "Encode 0x#{hex} => #{words.inspect}"
        expect(Sixword.encode(byte_string)).to eq(words)
      end
    end
  end

  it 'should decode RFC vectors to hex correctly' do
    Sixword::TestVectors::HexTests.each do |_section, tests|
      tests.each do |hex, sentence|
        words = sentence.split
        byte_string = Sixword::Hex.decode(hex)
        debug_puts "Decode #{words.inspect} => 0x#{hex}"
        expect(Sixword.decode(words)).to eq(byte_string)
      end
    end
  end

  it 'should decode with correct parity' do
    Sixword::TestVectors::ParityTest.find_all {|_k, v| v}.each do |sentence, _|
      debug_puts "correct parity: #{sentence.inspect}"
      expect { Sixword.decode(sentence) }.to_not raise_error
    end
  end
  it 'should raise with incorrect parity' do
    Sixword::TestVectors::ParityTest.find_all {|_k, v| !v}.each do |sentence, _|
      debug_puts "incorrect parity: #{sentence.inspect}"
      expect { Sixword.decode(sentence) }.
        to raise_error(Sixword::InvalidParity)
    end
  end

  it 'should reject encode inputs without padding' do
    expect { Sixword.encode('123') }.to raise_error(ArgumentError)
    expect { Sixword.encode('12345678X') }.to raise_error(ArgumentError)
  end
  it 'should reject decode inputs of wrong length' do
    expect { Sixword.decode('A') }.to raise_error(ArgumentError)
  end

  it 'should properly encode to sentences' do
    Sixword::TestVectors::HexTests.fetch('rfc 1751').each do |hex, sentence|
      # group into 6-word sentences
      sentences = sentence.split.each_slice(6).map {|s| s.join(' ')}
      byte_string = Sixword::Hex.decode(hex)
      debug_puts "Encoding #{hex.inspect} to sentences"
      debug_puts " => #{sentences.inspect}"
      expect(Sixword.encode_to_sentences(byte_string)).to eq(sentences)
    end
  end

  it 'should handle all null bytes correctly' do
    binary = "\0" * 8
    encoded = ['A'] * 6
    expect(Sixword.encode(binary)).to eq(encoded)
    expect(Sixword.decode(encoded)).to eq(binary)
  end

  it 'should handle padded null bytes correctly' do
    {
      "\0\0\0foo" => ["A", "A", "HAY", "SLEW", "TROT", "A2"],
      "\0\0\0foo\0\0" => ["A", "A", "HAY", "SLEW", "TROT", "A"],
      "foo\0\0" => ["CHUB", "EMIL", "MUDD", "A", "A", "A3"],
    }.each do |binary, encoded|
      expect(Sixword.pad_encode(binary)).to eq(encoded)
      expect(Sixword.pad_decode(encoded)).to eq(binary)
    end
  end

  it 'should convert hex strings to byte strings' do
    {"03e755bf6982fa55" => "\x03\xe7\x55\xbf\x69\x82\xfa\x55",
     "19dd19a502ca2d60" => "\x19\xdd\x19\xa5\x02\xca\x2d\x60",
     "1b208466c4560c93" => "\x1b\x20\x84\x66\xc4\x56\x0c\x93",
     "40026b4d6008286a" => "\x40\x02\x6b\x4d\x60\x08\x28\x6a",
     "4002 6b4d 6008 286a" => "\x40\x02\x6b\x4d\x60\x08\x28\x6a",

     "54686520717569636b2062726f776e20666f78206a756d7073206f7665722074686520" \
       "6c617a7920646f672e" =>
       "The quick brown fox jumps over the lazy dog.",

     "54686520717569636B2062726F776E20666F78206A756D7073206F7665722074686520" \
       "6C617A7920646F672E" =>
       "The quick brown fox jumps over the lazy dog.",
    }.each do |hex_string, byte_string|
      expect(Sixword::Hex.decode(hex_string)).to eq(byte_string)
    end
  end
end
