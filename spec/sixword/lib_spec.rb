require_relative '../rspec_helper'

describe Sixword::Lib do
  it 'should encode 64 bits correctly' do
    {
      [0xd1, 0x85, 0x42, 0x18, 0xeb, 0xbb, 0x0b, 0x51] =>
        %w{ROME MUG FRED SCAN LIVE LACE},
    }.each do |barray, sentence|
      debug_puts "Encoding bit array: #{barray.inspect}"
      Sixword::Lib.encode_64_bits(barray).should == sentence
    end
  end

  it 'should decode 6 words correctly into int64' do
    {
      %w{ROME MUG FRED SCAN LIVE LACE} => 0xD1854218EBBB0B51,
    }.each do |words, int|
      debug_puts "Decoding 6-word array: #{words.inspect}"
      Sixword::Lib.decode_6_words(words, false).should == int
    end
  end
end
