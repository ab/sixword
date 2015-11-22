RSpec.describe Sixword::Lib do
  it 'should encode 64 bits correctly' do
    {
      [0xd1, 0x85, 0x42, 0x18, 0xeb, 0xbb, 0x0b, 0x51] =>
        %w{ROME MUG FRED SCAN LIVE LACE},
    }.each do |barray, sentence|
      debug_puts "Encoding bit array: #{barray.inspect}"
      expect(Sixword::Lib.encode_64_bits(barray)).to eq(sentence)
    end
  end

  it 'should decode 6 words correctly into int64' do
    {
      %w{ROME MUG FRED SCAN LIVE LACE} => 0xD1854218EBBB0B51,
    }.each do |words, int|
      debug_puts "Decoding 6-word array: #{words.inspect}"
      expect(Sixword::Lib.decode_6_words(words, false)).to eq([int, 8])
    end
  end


  it 'should convert byte arrays to ints' do
    expect(Sixword::Lib.byte_array_to_int([1, 2])).to eq(258)
  end

  it 'should convert ints to byte arrays' do
    expect(Sixword::Lib.int_to_byte_array(258)).to eq([1, 2])
    expect(Sixword::Lib.int_to_byte_array(258, 3)).to eq([0, 1, 2])
  end
end
