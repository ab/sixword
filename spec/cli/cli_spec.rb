RSpec.describe Sixword::CLI do

  TestWarnings = Set.new
  def warn_once(label, message)
    unless TestWarnings.include?(label)
      warn message
      TestWarnings << label
    end
  end

  if RUBY_ENGINE == 'jruby' && JRUBY_VERSION.start_with?('1.7')
    RunningJruby17 = true
  else
    RunningJruby17 = false
  end

  # hack around jruby9 warnings on travis
  if RUBY_ENGINE == 'jruby' && ENV['TRAVIS'] && JRUBY_VERSION.start_with?('9.0')
    RunningTravisJruby9 = true
    SixwordOutputPrefix = "jruby: warning: unknown property jruby.cext.enabled\n" * 2
  else
    RunningTravisJruby9 = false
  end

  # Run a command with input and validate the expected output and exit status.
  def run(cmd, input_string, expected_output, expected_exitstatus=0)
    output = nil

    if RunningJruby17
      warn_once('jruby17', 'test warning: skipping unsupported popen option :err')
      opts = {}
    else
      opts = {err: [:child, :out]}
    end

    IO.popen(cmd, 'r+', opts) do |p|
      p.write(input_string)
      p.close_write
      output = p.read
    end

    if expected_output.is_a?(Regexp)
      expect(output).to match(expected_output)
    else
      expect(output).to eq(expected_output)
    end

    expect($?.exited?).to eq(true) unless RunningJruby17
    expect($?.exitstatus).to eq(expected_exitstatus)
  end

  SixwordExecutable = File.dirname(__FILE__) + '/../../bin/sixword'

  def run_sixword(opts, input_string, expected_output, expected_exitstatus=0)

    # hack around IO.popen stderr behavior in ruby 1.9
    if RUBY_VERSION.start_with?('1.9') && expected_exitstatus != 0 &&
       (expected_output.is_a?(Regexp) || !expected_output.empty?)

      warn_once('ruby19', "test warning: overriding output #{expected_output.inspect} with ''")
      expected_output = ''
    end

    if RunningTravisJruby9 && expected_output.is_a?(String)
      expected_output = SixwordOutputPrefix + expected_output
    end

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

  it 'should encode N sentences per line' do
    input = 'The quick brown fox jump'

    {
      0 => "BEAK US ACHE SOUR BERN LOLA CORE ARC HULK SLID DREW DUE CHUB ENDS BOG RUSS BESS MAST\n",
      1 => "BEAK US ACHE SOUR BERN LOLA\nCORE ARC HULK SLID DREW DUE\nCHUB ENDS BOG RUSS BESS MAST\n",
      2 => "BEAK US ACHE SOUR BERN LOLA CORE ARC HULK SLID DREW DUE\nCHUB ENDS BOG RUSS BESS MAST\n",
      3 => "BEAK US ACHE SOUR BERN LOLA CORE ARC HULK SLID DREW DUE CHUB ENDS BOG RUSS BESS MAST\n",
      4 => "BEAK US ACHE SOUR BERN LOLA CORE ARC HULK SLID DREW DUE CHUB ENDS BOG RUSS BESS MAST\n",
    }.each_pair do |width, expected_output|
      run_sixword(['-e', '-w %d' % width], input, expected_output)
    end
  end
end
