if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

# Check if the root certificate exists, if not, continue with generation
unless RubyCA::Core::Models::Config.get('first_run_complete')
  
  unless Process.euid == 0 
    puts ''
    puts 'Error: RubyCA requires root permissions to generate CA certificates, root privileges are dropped once the server starts.'
    puts "Please run RubyCA using 'sudo ./RubyCA'."
    abort
  end
  
  puts ''
  puts 'This appears to be RubyCA\'s first run. RubyCA will now generate the root and intermediate CA certificates.'

# Generate certificates  
  puts ''
  puts 'Generating root and intermediate certificates...'
  
  # Check folders and permissions
  if Dir.exist? $root_dir + '/private/' then FileUtils.rm_r $root_dir + '/private/' end
  Dir.mkdir $root_dir + '/private', 0755
  
  # Common variables
  cipher = OpenSSL::Cipher::Cipher.new 'AES-256-CBC'
  
  # Generate self signed root
  
  # Create root key
  root_key = OpenSSL::PKey::RSA.new 2048
  puts ''
  puts 'You will now be asked to enter a pass phrase for the root CA key. This is not stored by RubyCA.'
  open $root_dir + "/private/root_ca.pem", 'w', 0400 do |io|
    io.write root_key.export(cipher)
  end
  # Create root certificate
  root_name = OpenSSL::X509::Name.parse "C=#{CONFIG['ca']['root']['country']}/ST=#{CONFIG['ca']['root']['state']}/L=#{CONFIG['ca']['root']['locality']}/O=#{CONFIG['ca']['root']['organisation']}/CN=#{CONFIG['ca']['root']['cn']}"
  root_crt = OpenSSL::X509::Certificate.new
  root_crt.serial = 0x10000000000000000000000000000000 + rand(0x01000000000000000000000000000000)
  RubyCA::Core::Models::Config.create( name: 'last_serial', value: root_crt.serial.to_s )
  root_crt.version = 2
  root_crt.not_before = Time.utc(Time.now.year, Time.now.month, Time.now.day, 00, 00, 0)
  root_crt.not_after = root_crt.not_before  + (CONFIG['ca']['root']['years'] * 365 * 24 * 60 * 60 - 1) + ((CONFIG['ca']['root']['years'] / 4).to_int * 24 * 60 * 60)
  root_crt.public_key = root_key.public_key
  root_crt.subject = root_name
  root_crt.issuer = root_name
  root_ef = OpenSSL::X509::ExtensionFactory.new
  root_ef.subject_certificate = root_crt
  root_ef.issuer_certificate = root_crt
  root_crt.add_extension root_ef.create_extension 'subjectKeyIdentifier', 'hash'
  root_crt.add_extension root_ef.create_extension 'basicConstraints', 'CA:TRUE', true
  root_crt.add_extension root_ef.create_extension 'keyUsage', 'cRLSign,keyCertSign', true
  root_crt.add_extension root_ef.create_extension 'crlDistributionPoints', "URI:http://#{CONFIG['web']['host']}/ca.crl"
  root_crt.sign root_key, OpenSSL::Digest::SHA512.new
  @root_crt = RubyCA::Core::Models::Certificate.create( cn: "#{CONFIG['ca']['root']['cn']}" )
  @root_crt.crt = root_crt.to_pem
  @root_crt.save
  # Generate intermediate certificate
  
  # Generate intermediate key
  intermediate_key = OpenSSL::PKey::RSA.new 2048
  puts ''
  puts 'You will now be asked to enter a pass phrase for the intermediate CA key. This is not stored by RubyCA.'
  @intermediate_crt = RubyCA::Core::Models::Certificate.create( cn: "#{CONFIG['ca']['intermediate']['cn']}" )
  @intermediate_crt.pkey = intermediate_key.export(cipher)
  # Generate intermediate csr
  intermediate_csr = OpenSSL::X509::Request.new
  intermediate_csr.version = 2
  intermediate_csr.subject = OpenSSL::X509::Name.parse "C=#{CONFIG['ca']['intermediate']['country']}/ST=#{CONFIG['ca']['intermediate']['state']}/L=#{CONFIG['ca']['intermediate']['locality']}/O=#{CONFIG['ca']['intermediate']['organisation']}/CN=#{CONFIG['ca']['intermediate']['cn']}"
  intermediate_csr.public_key = intermediate_key.public_key
  intermediate_csr.sign intermediate_key, OpenSSL::Digest::SHA512.new
  # Sign intermediate csr with root certficate
  intermediate_crt = OpenSSL::X509::Certificate.new
  @serial = RubyCA::Core::Models::Config.get('last_serial')
  intermediate_crt.serial = @serial.value.to_i + 1
  @serial.value = intermediate_crt.serial.to_s
  @serial.save
  intermediate_crt.version = 2
  intermediate_crt.not_before = Time.utc(Time.now.year, Time.now.month, Time.now.day, 00, 00, 0)
  intermediate_crt.not_after = intermediate_crt.not_before  + (CONFIG['ca']['intermediate']['years'] * 365 * 24 * 60 * 60 - 1) + ((CONFIG['ca']['intermediate']['years'] / 4).to_int * 24 * 60 * 60)
  intermediate_crt.subject = intermediate_csr.subject
  intermediate_crt.public_key = intermediate_csr.public_key
  intermediate_crt.issuer = root_crt.subject
  intermediate_ef = OpenSSL::X509::ExtensionFactory.new
  intermediate_ef.subject_certificate = intermediate_crt
  intermediate_ef.issuer_certificate = root_crt
  intermediate_crt.add_extension intermediate_ef.create_extension 'subjectKeyIdentifier', 'hash'
  intermediate_crt.add_extension intermediate_ef.create_extension 'basicConstraints', 'CA:TRUE', true
  intermediate_crt.add_extension intermediate_ef.create_extension 'keyUsage', 'cRLSign,keyCertSign', true
  intermediate_crt.add_extension intermediate_ef.create_extension 'crlDistributionPoints', "URI:http://#{CONFIG['web']['host']}/ca.crl"
  intermediate_crt.sign root_key, OpenSSL::Digest::SHA512.new
  @intermediate_crt.crt = intermediate_crt.to_pem
  @intermediate_crt.save
  
  # Create CRL
  crl = OpenSSL::X509::CRL.new
  crl.version = 1
  crl.issuer = intermediate_crt.subject
  crl.last_update = Time.now
  crl.next_update = Time.now + 60 * 60 * 24 * 30
  crl.sign intermediate_key, OpenSSL::Digest::SHA512.new
  @crl = RubyCA::Core::Models::CRL.create( crl: crl.to_pem )
  
# Finish up
  puts ''
  puts 'Sucessfully generated root and imtermediate certificates.'
  
  puts ''
  puts '******************************************************************'
  puts '* Warning: The root private key has been encrypted and saved to  *'
  puts '* ./private/root_ca.pem                                          *'
  puts '* Consider moving it to a secure device.                         *'
  puts '******************************************************************'
  
  RubyCA::Core::Models::Config.create( name: 'first_run_complete', value: true )
end
  

