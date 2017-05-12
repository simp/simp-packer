#!/usr/bin/ruby
#
require 'yaml'

ipnetwork = ENV['SIMP_PACKER_network']
ipnetwork.nil? && ipnetwork = "192.168.50.0"
domain = ENV['SIMP_PACKER_domain']
domain.nil? && domain = "simp.test"
fips = ENV['SIMP_PACKER_fips']

network = ipnetwork.split(".")[0,3].join(".")

simpconfig = YAML.load_file('/var/local/simp/files/simp_conf.yaml')

simpconfig['cli::network::interface'] = "enps08"
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

File.open('/var/local/simp/files/simp_conf_updated.yaml','w') do |h|
     h.write simpconfig.to_yaml
end



