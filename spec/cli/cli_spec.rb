RSpec.describe Sixword::CLI do

  # Run a command with input and validate the expected output and exit status.
  def run(cmd, input_string, expected_output, expected_exitstatus=0)
    output = nil

    IO.popen(cmd, 'r+', err: [:child, :out]) do |p|
      p.write(input_string)
      p.close_write
      output = p.read
    end

    if expected_output.is_a?(Regexp)
      expect(output).to match(expected_output)
    else
      expect(output).to eq(expected_output)
    end

    expect($?.exited?).to eq(true)
    expect($?.exitstatus).to eq(expected_exitstatus)
  end

  SixwordExecutable = File.dirname(__FILE__) + '/../../bin/sixword'

  def run_sixword(opts, input_string, expected_output, expected_exitstatus=0)
    run([SixwordExecutable] + opts, input_string, expected_output, expected_exitstatus)
  end

  it 'handles basic encoding and decoding' do
    run_sixword(['-e'], "Testing\n", "BEAK NET SITE ROTH SWIM FORM\n")
    run_sixword([], "Testing\n", "BEAK NET SITE ROTH SWIM FORM\n")
    run_sixword(['-d'], "BEAK NET SITE ROTH SWIM FORM\n", "Testing\n")
    run_sixword(['-d'], "beak net site roth swim form\n", "Testing\n")

    run_sixword(['-v'], '', 'sixword ' + Sixword::VERSION + "\n")
  end

  it 'returns expected error codes in various conditions' do
    run_sixword(%w{-e --hex-style nonexistent}, '', /unknown hex style/, 2)
    run_sixword(['-d'], "BEAK NET SITE ROTH SWIM FOR\n", /Parity bits do not match/, 3)
    run_sixword(['-d'], "ZZZ A A A A A\n", /Unknown word: "ZZZ"/, 4)
    run_sixword(['-d'], "AAAAAA A A A A A\n", /1-4 chars/, 5)

    run_sixword(['-d'], "A\n", /multiple of 6 words/, 10)
  end

  it 'handles padding' do
    run_sixword([], 'foo', "CHUB EMIL MUDD A A A5\n")
    run_sixword(['-d'], "CHUB EMIL MUDD A A A5\n", 'foo')
  end

  it 'rejects padding when -p is given' do
    run_sixword(['-ep'], '.', /multiple of 8 or use pad_encode/, 10)
    run_sixword(['-dp'], "CHUB EMIL MUDD A A A5\n", /Unknown word: "A5"/, 4)
  end

  it 'handles basic hex styles' do
    run_sixword(['-H'], "54:65:73:74:69:6e:67:0a\n", "BEAK NET SITE ROTH SWIM FORM\n")
    run_sixword(['-H'], "54657374696e670a\n", "BEAK NET SITE ROTH SWIM FORM\n")
    run_sixword(['-H'], "5465 7374 696E 670A\n", "BEAK NET SITE ROTH SWIM FORM\n")

    run_sixword(['-dH'], "BEAK NET SITE ROTH SWIM FORM\n", "54657374696e670a\n")
    run_sixword(['-df'], "BEAK NET SITE ROTH SWIM FORM\n", "5465 7374 696E 670A\n")
    run_sixword(%w{-d -S colons}, "BEAK NET SITE ROTH SWIM FORM\n", "54:65:73:74:69:6e:67:0a\n")
  end

  it 'should encode/decode RFC hex vectors correctly' do
    Sixword::TestVectors::HexTests.each do |_section, tests|
      tests.each do |hex, sentence|
        debug_puts "0x#{hex} <=> #{sentence}"

        if sentence.split.length > 6
          expected_encoded = sentence.split.each_slice(6).map {|line| line.join(' ')}.join("\n")
        else
          expected_encoded = sentence
        end

        run_sixword(['-df'], sentence, hex + "\n")
        run_sixword(['-ef'], hex, expected_encoded + "\n")
      end
    end
  end

  it 'should handle all null bytes correctly' do
    run_sixword(['-ep'], "\0" * 8, "A A A A A A\n")
    run_sixword(['-dp'], "A A A A A A\n", "\0" * 8)
  end

  it 'should handle padded null bytes correctly' do
    {
      "\0\0\0foo" => ["A", "A", "HAY", "SLEW", "TROT", "A2"],
      "\0\0\0foo\0\0" => ["A", "A", "HAY", "SLEW", "TROT", "A"],
      "foo\0\0" => ["CHUB", "EMIL", "MUDD", "A", "A", "A3"],
    }.each do |binary, encoded|
      encoded_s = encoded.join(' ') + "\n"
      run_sixword(['-e'], binary, encoded_s)
      run_sixword(['-d'], encoded_s, binary)
    end
  end
end
