# Sixword

Sixword implements the 6-word binary encoding created for S/Key (tm) and
standardized by RFC 2289, RFC 1760, and RFC 1751. Binary data may be
encoded using a dictionary of 2048 English words of 1-4 characters in
length. Each block of 64 bits is encoded using 6 words, which includes 2
parity bits. It is ideal for transmitting binary data such as cryptographic
keys where humans must communicate or enter the values.

## Comparison to other encodings

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

See also: Bubble Babble, PGP Word List, Diceware, Base64, Base32

## Installation

Add this line to your application's Gemfile:

    gem 'sixword'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sixword

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
