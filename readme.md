# RubyCA

## About
RubyCA is a simple certificate authority manager written in Ruby.

It is designed for internal use as an alternative to using self signed certificates. Install and trust the root certificate in your clients and any certificates you create will just work, no more browser warnings.

## Development
RubyCA is currently in development and not all features are implemented. 

Currently, RubyCA will generate root and intermediate CA certificates. The web UI can be used to manage signing requests, certificates and revokations, as well as to download certificates and keys and serve the certificate revocation list. 

In the future the web UI will support the Online Certificate Status Protocol (OCSP).

The currently isn't much error checking, this will be added in the future.

Pull requests welcome.

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
    
Visit http:// *host* : *port* /admin to manage certificates

## Tips

RubyCA will be able to be ran as a daemon if the future, but for now you can use 'screen' to run it in the background.

    $ screen -S 'RubyCA' -d -m ./RubyCA
    
You can then access the running screen session with:
    
    $ screen -r 'RubyCA'