# Change Log
All notable changes to Sixword should be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org).

## [Unreleased]

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
