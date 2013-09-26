require_relative 'rspec_helper'

describe Sixword do
  it 'should encode RFC hex vectors correctly' do
    Sixword::TestVectors::HexTests.each do |section, tests|
      tests.each do |hex, sentence|
        words = sentence.split
        byte_string = Sixword.hex_string_to_byte_string(hex)
        puts "Checking encode 0x#{hex} => #{words.inspect}"
        Sixword.encode(byte_string).should == words
      end
    end
  end

  it 'should decode RFC vectors to hex correctly' do
    Sixword::TestVectors::HexTests.each do |section, tests|
      tests.each do |hex, sentence|
        words = sentence.split
        byte_string = Sixword.hex_string_to_byte_string(hex)
        puts "Checking decode #{words.inspect} => 0x#{hex}"
        Sixword.decode(words).should == byte_string
      end
    end
  end
end
