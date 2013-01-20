# RubyCA

## About
RubyCA is a simple certificate authority manager written in Ruby.

## Development
RubyCA is currently in development and not all features are implemented. 

Currently, RubyCA will generate root and intermediate CA certificates. The web UI can be used to create signing requests and certificates, as well as to download certificates and keys. In the future the web UI will support certificate revocation lists and the Online Certificate Status Protocol (OCSP).

The currently isn't much error checking, this will be added in the future.

## Usage

Clone and enter the repository

    $ git clone https://github.com/phillcampbell/RubyCA.git
    $ cd RubyCA

Use bundle to install dependencies

    $ bundle install
    
Edit the config.yaml file to suit your requirements

    $ nano ./config.yaml

RubyCA must be started as root on the first run to be able to generate the ca certificates

    $ sudo ./RubyCA