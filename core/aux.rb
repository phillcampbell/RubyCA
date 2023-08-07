if __FILE__ == $0 then abort 'This file forms part of RubyCA and is not designed to be called directly. Please run ./RubyCA instead.' end

def get_crl_dist_uri
  # CRL distribuition URI.
  crldist=nil
  unless CONFIG['ca']['crl']['dist'].nil? || CONFIG['ca']['crl']['dist']['uri'].nil? || CONFIG['ca']['crl']['dist']['uri'].empty? || CONFIG['ca']['crl']['dist']['uri'] ===''
    crldist = CONFIG['ca']['crl']['dist']['uri'].map{|uri| "URI:#{uri}"}.join(',')
  end
  return crldist
  puts "From setup"
end