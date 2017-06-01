#!/usr/bin/env ruby
#
#This is going to take the files in the test directory and update
#what needs to be updated in the configuration files according
#to the packer.yaml settings and move them to the working directory.
#The working directory is what is copied to simp server.
#
def checkip(ip)
  block = /\d{,2}|1\d{2}|2[0-4]\d|25[0-5]/
  re = /\A#{block}\.#{block}\.#{block}\.#{block}\z/
  re =~ ip
end
 
# encrypt_openldap_hash is borrowed from simp-cli
def encrypt_openldap_hash( string, salt=nil )
   require 'digest/sha1'
   require 'base64'

   # Ruby 1.8.7 hack to do Random.new.bytes(4):
   salt   = salt || (x = ''; 4.times{ x += ((rand * 255).floor.chr ) }; x)
   digest = Digest::SHA1.digest( string + salt )

   # NOTE: Digest::SHA1.digest in Ruby 1.9+ returns a String encoding in
   #       ASCII-8BIT, whereas all other Strings in play are UTF-8
   if RUBY_VERSION.split('.')[0..1].join('.').to_f > 1.8
     digest = digest.force_encoding( 'UTF-8' )
     salt   = salt.force_encoding( 'UTF-8' )
   end

   "{SSHA}"+Base64.encode64( digest + salt ).chomp
end

def getjson(json_file)
  if File.file?(json_file)
    f = File.open(json_file,'r')
    json = String.new
    #remove all the comments I put in the json file
    # so I could remember why I did stuff
    f.each {|line|
      unless  line[0] == '#'
        json = json + line
      end
    }
    f.close
    json
  else
    raise "JSON template file does not exist or is not a file."
  end
end

require 'yaml'
require 'json'

workingdir = ARGV[0]
testdir = ARGV[1]
basedir = File.expand_path(File.dirname(__FILE__))
json_tmp="#{basedir}/simp.json.template"

settings = YAML.load_file("#{testdir}/packer.yaml")
simpconfig = YAML.load_file("#{testdir}/simp_conf.yaml")

domain = settings['DOMAIN']

if settings.has_key?('HOST_ONLY_NETWORK')
  ipnetwork = settings['HOST_ONLY_NETWORK']
  if checkip(ipnetwork) == nil
    raise "Error: Packer.yaml setting HOST_ONLY_NETWORK not a valid ip: #{ipnetwork}"
  end
  network = ipnetwork.split(".")[0,3].join(".")
else
  raise "Error: Packer.yaml setting HOST_ONLY_NETWORK not set"
end

if settings.has_key?('HOST_ONLY_INTERFACE')
    iface = settings['HOST_ONLY_INTERFACE']
else
    puts "HOST_ONLY_INTERFACE must be set in packer.yaml"
end
# Default fips to true

if settings.has_key?('FIPS')
    fips = settings['FIPS'].eql?('fips=0')
end

if settings.has_key?('HOST_ONLY_GATEWAY')
 simpconfig['cli::network::gateway'] = settings['HOST_ONLY_GATEWAY']
else
 simpconfig['cli::network::gateway'] = network + ".1"
end

if settings.has_key?('PUPPETIP')
  simpconfig['simp_options::dns::servers'] = settings['PUPPETIP']
  simpconfig['cli::network::ipaddress'] = settings['PUPPETIP']
else
  simpconfig['simp_options::dns::servers'] = network + ".7"
  simpconfig['cli::network::ipaddress'] = network + ".7"
end

if settings.has_key?('PUPPETNAME')
  simpconfig['simp_options::puppet::server'] = settings['PUPPETNAME']
else
  simpconfig['simp_options::puppet::server'] = "puppet" + "." + domain
end
simpconfig['cli::network::hostname'] = simpconfig['simp_options::puppet::server']
simpconfig['simp_options::puppet::ca'] = simpconfig['simp_options::puppet::server']
simpconfig['cli::network::interface'] = iface
simpconfig['cli::network::netmask'] = "255.255.255.0"
simpconfig['simp_options::dns::search'] = [ domain ]
simpconfig['simp_options::trusted_nets']= network + ".0/24"
simpconfig['simp_options::ldap::base_dn'] = "dc=" + domain.split(".").join(",dc=")
simpconfig['simp_options::fips'] = fips.eql? "fips=0"
simpconfig['simp_options::ntpd::servers'] = simpconfig['cli::network::gateway']

File.open("#{workingdir}/files/simp_conf.yaml",'w') do |h|
     h.write simpconfig.to_yaml
     h.close
end

# Now replace settings in the json file with packer.yaml settings
json = getjson json_tmp

settings.each { |key, value|
  json.gsub!(key,value)
}

File.open("#{workingdir}/simp.json",'w') { |h|
     h.write json
     h.close
}
