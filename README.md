# Sixword

[![Gem Version](https://badge.fury.io/rb/sixword.svg)](https://rubygems.org/gems/sixword)
[![Build status](https://travis-ci.org/ab/sixword.svg)](https://travis-ci.org/ab/sixword)
[![Code Climate](https://codeclimate.com/github/ab/sixword.svg)](https://codeclimate.com/github/ab/sixword)
[![Inline Docs](http://inch-ci.org/github/ab/sixword.svg?branch=master)](http://www.rubydoc.info/github/ab/sixword/master)

Sixword implements the 6-word binary encoding created for S/Key (tm) and
standardized by RFC 2289, RFC 1760, and RFC 1751. Binary data may be
encoded using a dictionary of 2048 English words of 1-4 characters in
length. Each block of 64 bits is encoded using 6 words, which includes 2
parity bits. It is ideal for transmitting binary data such as cryptographic
keys where humans must communicate or enter the values.

## Comparison to other encodings

See also: Bubble Babble, PGP Word List, Diceware, Base64, Base32

- Bubble Babble does not use full words, so it is more difficult for humans to
  type or communicate over the phone.

- The PGP Word List is optimized for communicating fingerprints, so it uses
  much longer and more distinct words. This is less convenient when you
  actually expect a human to type the whole sentence. Sixword handles error
  detection with the built-in parity bits.

- Diceware is optimized for creating passphrases by a roll of standard 6-sided
  dice, so it uses a word list that is a power of 6. This is not very
  convenient as an encoding for arbitrary binary data.

- Base64 is well suited as a machine encoding where an ASCII transport is
  desired. It is not very convenient for humans, and has no parity built in.

- Base32 is somewhat better for humans than Base64 because it is case
  insensitive and doesn't include 0 or 1. However it is still not very
  convenient for humans to type or visually inspect.

## Installation

Add this line to your application's Gemfile:

    gem 'sixword'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sixword

## Usage: Command Line

Sixword operates similarly to `base64(1)`, it operates on a file or on STDIN in two modes:

- encode: accept binary data (or hexadecimal in hex modes) and print six-word
  encoded data on stdout.
- decode: accept six-word encoded data and print binary data (or hex) on
  stdout.

### Examples

Normal encoding and decoding

    $ sixword <<< 'Testing'
    BEAK NET SITE ROTH SWIM FORM

    $ sixword -d <<< 'BEAK NET SITE ROTH SWIM FORM'
    Testing

    $ sixword -d <<< 'beak net site roth swim form'
    Testing

The same data, but hex encoded

    $ sixword -H <<< '54:65:73:74:69:6e:67:0a'
    BEAK NET SITE ROTH SWIM FORM

    $ sixword -dH <<< 'BEAK NET SITE ROTH SWIM FORM'
    54657374696e670a

    $ sixword -dF <<< 'BEAK NET SITE ROTH SWIM FORM'
    5465 7374 696E 670A

    $ sixword -d -S colons <<< 'BEAK NET SITE ROTH SWIM FORM'
    54:65:73:74:69:6e:67:0a

Error handling

    $ sixword -d <<< 'BEAK NET SITE ROTH SWIM FOR'
    sixword: Parity bits do not match
    [exit status 3]

    $ sixword -p <<< '.'
    sixword: Must pad bytes to multiple of 8 or use pad_encode

## Usage: Library

See the [YARD documentation](http://www.rubydoc.info/github/ab/sixword/master).
The top-level `Sixword` module contains the main API (`Sixword.encode` and
`Sixword.decode`), while various utilities can be found in `Sixword::Hex` and
`Sixword::Lib`. Most of the code powering the command line interface is in
`Sixword::CLI`.

    >> require 'sixword'

    >> Sixword.encode('Hi world')
    => ["ACRE", "ADEN", "INN", "SLID", "MAD", "PAP"]

    >> Sixword.decode(["ACRE", "ADEN", "INN", "SLID", "MAD", "PAP"])
    => 'Hi world'

    >> Sixword.decode("acre aden inn slid mad pap")
    => 'Hi world'

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
