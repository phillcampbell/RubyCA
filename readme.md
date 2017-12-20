# RubyCA

## About
RubyCA is a simple certificate authority manager written in Ruby.

Forked from https://github.com/phillcampbell/RubyCA.git

It is designed for internal use as an alternative to using self signed certificates. Install and trust the root certificate in your clients and any certificates you create will just work, no more browser warnings.

## Development
RubyCA is currently in development and not all features are implemented. 

Currently, RubyCA will generate root and intermediate CA certificates. The web UI can be used to manage signing requests, certificates and revokations, as well as to download certificates and keys and serve the certificate revocation list. 

In the future the web UI will support the Online Certificate Status Protocol (OCSP).

The currently isn't much error checking, this will be added in the future.

Pull requests welcome.

## Usage

Clone and enter the repository

    $ git clone https://github.com/oferreiro/RubyCA.git
    $ cd RubyCA

Use bundle to install dependencies

    $ bundle install
    
Create the config.yaml file and edit to suit your requirements

    $ cp ./config.yaml.sample ./config.yaml
    $ nano ./config.yaml

RubyCA must be started as root on the first run to be able generate the ca certificates

    $ sudo ./RubyCA
    
Visit http://<host>:<port>/admin to manage certificates

## Tips

To be able to be run RubyCA as daemon

####Using puma:

    $ cp ./distrib/puma/puma-sample.rb ./puma.rb
    nano ./puma.rb

RubyCA must be started with:

    $ bundle exec thin puma -C ./puma.rb    

####Using Thin:

Create the thin.yaml file and edit to suit your requirements.

    $ cp ./distrib/thin/thin.yaml.sample ./thin.yaml
    $ nano ./thin.yaml

Edit Gemfile to use thin server:

    gem 'thin', '~> 1.7', '>= 1.7.2'
    #gem 'puma', '~> 3.11'

Run bundle:

    $ bundle
  
RubyCA must be started with:

    $ bundle exec thin start -C ./thin.yaml

Note:
The first run still needs RubyCA run as root to be able generate the ca certificates.
  
    $ sudo ./RubyCA

Or run in unsafe mode (-u|--unsafe) if you want keep user privileges on root ca private key.

    $./RubyCA --unsafe