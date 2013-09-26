# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sixword/version'

Gem::Specification.new do |spec|
  spec.name          = 'sixword'
  spec.version       = Sixword::VERSION
  spec.authors       = ['Andy Brody']
  spec.email         = ['abrody@abrody.com']
  spec.summary       = 'Implementation of RFC 2289 compatible 6-word encoding'
  spec.description   = <<-EOM
    Sixword implements the 6-word binary encoding created for S/Key (tm) and
    standardized by RFC 2289, RFC 1760, and RFC 1751. Binary data may be
    encoded using a dictionary of 2048 English words of 1-4 characters in
    length. Each block of 64 bits is encoded using 6 words, which includes 2
    parity bits. It is ideal for transmitting binary data such as cryptographic
    keys where humans must communicate or enter the values.

    See also: Bubble Babble, PGP Word List, Diceware, Base64, Base32
  EOM
  spec.homepage      = 'https://github.com/ab/sixword'
  spec.license       = 'GPL-3'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
