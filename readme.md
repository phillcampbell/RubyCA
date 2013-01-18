# RubyCA

## About
RubyCA is a simple certificate authority manager written in Ruby.

## Development
RubyCA is currently in development and not all features are implemented. 

Currently, RubyCA will generate root and intermediate CA certificates. In the future RubyCA will have a web UI for creating, signing and revoking certificates and will support certificate revocation lists and the Online Certificate Status Protocol (OCSP).

## Usage

Clone and enter the repository

    $ git clone https://github.com/phillcampbell/ruby_ca.git
    $ cd ruby_ca

Use bundle to install dependencies

    $ bundle install

RubyCA must be started as root on the first run to be able to generate the ca certificates

    $ sudo ./RubyCA