if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

# Check if the root certificate exists, if not, continue with generation
unless File.exist?($root_dir + "/certificates/#{CONFIG['ca']['root']['name']}_Root_CA.crt")
  
  puts 'Root CA certificate not found. RubyCA will now generate the root and intermediate CA certificates.'
  
  unless Process.euid == 0 
    puts ''
    puts 'Error: RubyCA requires root permissions to securely create the CA keys.'
    puts "Please run RubyCA using 'sudo ./RubyCA'."
    abort
  end

# Generate certificates  
  puts ''
  puts "Warning: RubyCA will destroy the directories './keys' and './certificates' if they already exist."
  puts "Type 'YES' to continue, otherwise RubyCA will exit:"
  unless gets.chomp == 'YES' then abort end

  puts ''
  puts 'Generating root and intermediate certificates...'
  
  # Check folders and permissions
  if Dir.exist? $root_dir + '/keys' then FileUtils.rm_r $root_dir + '/keys' end
  Dir.mkdir $root_dir + '/keys', 0755
  File.chmod 0755, $root_dir + '/keys'
  if Dir.exist? $root_dir + '/certificates' then FileUtils.rm_r $root_dir + '/certificates' end
  Dir.mkdir $root_dir + '/certificates', 0755
  File.chmod 0755, $root_dir + '/certificates'
  
  # Common variables
  cipher = OpenSSL::Cipher::Cipher.new 'AES-256-CBC'
  
  # Generate self signed root
  
  # Create root key
  root_key = OpenSSL::PKey::RSA.new 2048
  puts ''
  puts 'You will now be asked to enter a pass phrase for the root CA key. This is not stored by RubyCA.'
  open $root_dir + "/keys/#{CONFIG['ca']['root']['name']}_Root_CA.pem", 'w', 0400 do |io|
    io.write root_key.export(cipher)
  end
  # Create root certificate
  root_name = OpenSSL::X509::Name.parse "C=#{CONFIG['ca']['root']['country']}/ST=#{CONFIG['ca']['root']['state']}/L=#{CONFIG['ca']['root']['locality']}/O=#{CONFIG['ca']['root']['name']} Root CA/CN=#{CONFIG['ca']['root']['name']} Root Certificate Authority"
  root_crt = OpenSSL::X509::Certificate.new
  root_crt.serial = 0x10000000000000000000000000000000 + rand(0x01000000000000000000000000000000)
  open $root_dir + '/core/ca/last_serial', 'w' do |io|
    io.write root_crt.serial
  end
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
  open $root_dir + "/certificates/#{CONFIG['ca']['root']['name']}_Root_CA.crt", 'w', 0444 do |io|
    io.write root_crt.to_pem
  end
  
  # Generate intermediate certificate
  
  # Generate intermediate key
  intermediate_key = OpenSSL::PKey::RSA.new 2048
  puts ''
  puts 'You will now be asked to enter a pass phrase for the intermediate CA key. This is not stored by RubyCA.'
  open $root_dir + "/keys/#{CONFIG['ca']['intermediate']['name']}_Intermediate_CA.pem", 'w', 0400 do |io|
    io.write intermediate_key.export(cipher)
  end
  # Generate intermediate csr
  intermediate_csr = OpenSSL::X509::Request.new
  intermediate_csr.version = 2
  intermediate_csr.subject = OpenSSL::X509::Name.parse "C=#{CONFIG['ca']['intermediate']['country']}/ST=#{CONFIG['ca']['intermediate']['state']}/L=#{CONFIG['ca']['intermediate']['locality']}/O=#{CONFIG['ca']['intermediate']['name']} Intermediate CA/CN=#{CONFIG['ca']['intermediate']['name']} Intermediate Certificate Authority"
  intermediate_csr.public_key = intermediate_key.public_key
  intermediate_csr.sign intermediate_key, OpenSSL::Digest::SHA512.new
  # Sign intermediate csr with root certficate
  intermediate_crt = OpenSSL::X509::Certificate.new
  intermediate_crt.serial = IO.binread($root_dir + '/core/ca/last_serial').to_i + 1
  open $root_dir + '/core/ca/last_serial', 'w' do |io|
    io.write intermediate_crt.serial
  end
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

  open $root_dir + "/certificates/#{CONFIG['ca']['intermediate']['name']}_Intermediate_CA.crt", 'w' do |io|
    io.write intermediate_crt.to_pem
  end

# Finish up
  puts ''
  puts 'Sucessfully generated root and imtermediate certificates.'
  
# Drop privileges
  puts ''
  puts 'Dropping privileges...'
  Process::Sys.setuid(Etc.getpwnam('nobody').uid)
  # Check RubyCA has drops its privileges successfully
  begin
    Process::Sys.setuid(0)
  rescue Errno::EPERM
    puts "Successfully dropped privileges. RubyCA is now '#{Etc.getpwuid(Process.euid).name}'"
  else
    puts 'Error: Failed to drop privileges, RubyCA will now exit.'
    abort
  end
  
  puts ''
  puts '******************************************************************'
  puts '* Warning: Although the root and intermediate keys are encrypted *'
  puts '* the are still sensitive files. Ensure they are protected and   *'
  puts '* consider moving them to a secure device.                       *'
  puts '******************************************************************'
  
end
  

