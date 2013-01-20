# RubyCA

## About
RubyCA is a simple certificate authority manager written in Ruby.

## Development
RubyCA is currently in development and not all features are implemented. 

Currently, RubyCA will generate root and intermediate CA certificates. The web UI can be used to manage signing requests, certificates and revokations, as well as to download certificates and keys and serve the certificate revocation list. 

In the future the web UI will support the Online Certificate Status Protocol (OCSP).

The currently isn't much error checking, this will be added in the future.

## Usage

Clone and enter the repository

    $ git clone https://github.com/phillcampbell/RubyCA.git
    $ cd RubyCA

Use bundle to install dependencies

    $ bundle install
    
Create the config.yaml file and edit to suit your requirements

    $ cp ./config.yaml.sample ./config.yaml
    $ nano ./config.yaml

RubyCA must be started as root on the first run to be able to generate the ca certificates

    $ sudo ./RubyCA