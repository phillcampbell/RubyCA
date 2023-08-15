if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

def get_crl_dist_uri
  # CRL distribuition URI.
  crldist=nil
  unless $config['ca']['crl']['dist'].nil? || $config['ca']['crl']['dist']['uri'].nil? || $config['ca']['crl']['dist']['uri'].empty? || $config['ca']['crl']['dist']['uri'] ===''
    crldist = $config['ca']['crl']['dist']['uri'].map{|uri| "URI:#{uri}"}.join(',')
  end
  return crldist
  puts "From setup"
end