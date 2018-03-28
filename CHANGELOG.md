# Change Log
All notable changes to Sixword should be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org).

## [Unreleased]

## [0.3.5] -- 2018-03-28

- Fix up rubocop config etc.

## [0.3.4] -- 2015-12-06

- Add multi-sentence output option for encoding mode (-w, --line-width). This
  allows users to output multiples of 6 words on a line when encoding.

## [0.3.3] -- 2015-12-01

- Fix handling of words that straddle the 2048-byte buffer boundary. Previously
  any word that was split over the boundary would be mangled into two words,
  resulting in an error or incorrect output. This only affected the sixword
  CLI. [#3](https://github.com/ab/sixword/issues/3)

## [0.3.2] -- 2015-11-25

- Add lots of documentation and a change log!
- Upgrade tests to rspec 3.
- Introduce rubocop style config and fix lots of warnings.
- Make `sixword --version` actually work.

## [0.3.1] -- 2015-03-21

- Run tests on travis on various ruby versions.
- Fix tests on ruby 2.0+
- Add `-e` option flag to the CLI.

## [0.3.0] -- 2014-07-10

- Fix handling of leading null bytes.

## [0.2.0] -- 2013-09-27

- Add a command line interface, `sixword`.
- Handle various forms of hexadecimal notations, including colon or whitespace
  delimited fingerprints.

## [0.1.0] -- 2013-09-26

- Add and implement custom padding scheme for strings that are not a multiple
  of 8 bytes.
- Add lots of tests and refactor the code.

## [0.0.1] -- 2013-09-25

- Initial public release

<!-- vim: set tw=79 : -->
