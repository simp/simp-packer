#!/usr/bin/env ruby
#
#This is going to take the files in the test directory and update
#what needs to be updated in the configuration files according
#to the packer.yaml settings and move them to the working directory.
#The working directory is what is copied to simp server.
#
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
simpconfig['cli::network::ipaddress'] = network + ".7"
simpconfig['cli::network::netmask'] = "255.255.255.0"
simpconfig['cli::network::gateway'] = network + ".1"
simpconfig['simp_options::dns::servers'] = network + ".7"
simpconfig['simp_options::dns::search'] = [ domain ]
simpconfig['simp_options::trusted_nets']= network + ".0/24"
simpconfig['simp_options::puppet::server'] = "puppet" + "." + domain
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
Dir.mkdir("#{workingdir}/ldifs")
Dir.foreach("#{basedir}/ldifs") do |file|
  if File.file?(file)
    ldiffile = File.open(file,'rb')
    contents = ldiffile.read
    ldiffile.close
    contents.gsub!("LDAPBASEDN",simpconfig['simp_options::ldap::base_dn'])
    fname = File.basename("#{file}")
    File.open("#{workingdir}/ldifs/#{fname}",'w') do |h|
      h.write(contents)
      h.close
    end
  end
end




