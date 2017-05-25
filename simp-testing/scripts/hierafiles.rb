#!/usr/bin/env ruby
#
#This is going to take the files in the test directory and update
#what needs to be updated in the configuration files according
#to the packer.yaml settings and move them to the working directory.
#The working directory is what is copied to simp server.
#
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

require 'yaml'

workingdir = ARGV[0]
testdir = ARGV[1]
basedir = File.expand_path(File.dirname(__FILE__))

settings = YAML.load_file("#{testdir}/packer.yaml")
ipnetwork = settings['HOST_ONLY_NETWORK']
domain = settings['DOMAIN']
fips = settings['FIPS']

network = ipnetwork.split(".")[0,3].join(".")

simpconfig = YAML.load_file("#{testdir}/simp_conf.yaml")
#
#TODO:  Update the cli::network::interface to determine what is is from
#ip addr or something similiar so this will work for CentOS 6
simpconfig['cli::network::interface'] = "enp0s8"
simpconfig['cli::network::netmask'] = "255.255.255.0"
simpconfig['cli::network::gateway'] = network + ".1"
simpconfig['simp_options::dns::servers'] = network + ".7"
simpconfig['cli::network::ipaddress'] = network + ".7"
simpconfig['simp_options::dns::search'] = [ domain ]
simpconfig['simp_options::trusted_nets']= network + ".0/24"
simpconfig['simp_options::puppet::server'] = "puppet" + "." + domain
simpconfig['cli::network::hostname'] = simpconfig['simp_options::puppet::server']
simpconfig['simp_options::puppet::ca'] = simpconfig['simp_options::puppet::server']
simpconfig['simp_options::ldap::base_dn'] = "dc=" + domain.split(".").join(",dc=")
simpconfig['simp_options::fips'] = fips.eql? "fips=0"
simpconfig['simp_options::ntpd::servers'] = simpconfig['cli::network::gateway']

File.open("#{workingdir}/files/simp_conf.yaml",'w') do |h|
     h.write simpconfig.to_yaml
     h.close
end

# While we are at it we will update the ldif files with the basedn
# and copy them to the working directory
#  TODO might want to move this to the simp server
if ! Dir.exists?("#{workingdir}/files/ldifs")
  Dir.mkdir("#{workingdir}/files/ldifs")
end

Dir.foreach("#{basedir}/files/ldifs") do |file|
  if ! File.directory?("#{basedir}/files/ldifs/#{file}")
    ldiffile = File.open("#{basedir}/files/ldifs/#{file}",'rb')
    contents = ldiffile.read
    ldiffile.close
    contents.gsub!("LDAPBASEDN",simpconfig['simp_options::ldap::base_dn'])
    fname = File.basename("#{file}")
    File.open("#{workingdir}/files/ldifs/#{fname}",'w') do |h|
      h.write(contents)
      h.close
    end
  end
end

