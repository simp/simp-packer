#!/usr/bin/env ruby
# Update config files with packer.yaml setting and copy to working dir
#
# This is going to take the files in the test directory and update
# what needs to be updated in the configuration files according
# to the packer.yaml settings and move them to the working directory.
# The working directory is what is copied to simp server.
#
require 'simp/packer/vagrantfile_template'

class Utils
  def self.encrypt_openldap_hash(string, salt = nil)
    require 'digest/sha1'
    require 'base64'

    salt ||= Random.new.bytes(4)
    digest = Digest::SHA1.digest(string + salt)

    # NOTE: Digest::SHA1.digest in Ruby 1.9+ returns a String encoding in
    #       ASCII-8BIT, whereas all other Strings in play are UTF-8
    if RUBY_VERSION.split('.')[0..1].join('.').to_f > 1.8
      digest = digest.force_encoding('UTF-8')
      salt   = salt.force_encoding('UTF-8')
    end

    '{SSHA}' + Base64.encode64(digest + salt).chomp
  end
end

######################################################################
# Remove all the comments from a json template file
def read_and_strip_comments_from_file(json_file)
  raise "JSON file '#{json_file}' doees not exist or is not a file." unless File.file?(json_file)
  f = File.open(json_file, 'r')
  json = ''
  f.each do |line|
    json += line unless line.to_s =~ %r{^(\s*(#|//))}
  end
  f.close
  json
end

#####################################################################

def validate_settings(settings)
  validated = settings
  case settings['firmware']
  when 'bios', 'efi'
    validated['firmware'] = settings['firmware']
  else
    validated['firmware'] = 'bios'
  end

  case settings['headless']
  when %r{[Yy][Ee][Ss]}, true, 'true', %r{[Yy]}
    validated['headless'] = 'true'
  when %r{[Nn][Oo]?}, 'false', false
    validated['headless'] = 'false'
  else
    validated['headless'] = 'true'
    puts "Invalid setting for Headless #{settings['headless']} using 'true'"
  end

  case settings['disk_encrypt']
  when 'simp_crypt_disk', 'simp_disk_crypt'
    validated['disk_encrypt'] = 'simp_crypt_disk'
  else
    validated['disk_encrypt'] = ''
  end

  validated
end
#####################################################################

def update_hash(json_hash, settings)
  time = Time.new
  json_hash = json_hash.merge(settings)
  json_hash['postprocess_output'] = settings['output_directory']
  json_hash['output_directory'] = settings['output_directory'] + '/' + time.strftime('%Y%m%d%H%M')
  json_hash['host_only_network_name'] = getvboxnetworkname(settings['host_only_gateway'])
  if json_hash['host_only_network_name'].nil?
    raise "Error: could not create or find a virtualbox network for #{settings['host_only_gateway']}"
  end
  json_hash
end

# #####################################################################3
def getvboxnetworkname(network)
  vboxnet = nil
  hostonlylist = {}
  name = nil
  ipaddr = nil

  # Get the list of virtual box networks
  list = %x(VBoxManage list hostonlyifs).split("\n\n")
  list.each do |x|
    nw = x.split("\n")
    nw.each do |y|
      entry = y.split(':')
      case entry[0]
      when 'Name'
        name = entry[1].strip
      when 'IPAddress'
        ipaddr = entry[1].strip
      end
    end
    hostonlylist[name] = ipaddr
  end
  # Check if the network exists and return it name if it does
  hostonlylist.each { |net_name, ip| return(net_name) if ip.eql?(network) }

  # Network does not exist, create it and return the name
  puts "creating new Virtualbox hostonly network for #{network}"
  newnet = %x(VBoxManage hostonlyif create)
  if newnet.include? 'was successfully created'
    x = newnet.split("'")
    vboxnet = x[1]
    unless system("VBoxManage hostonlyif ipconfig #{vboxnet} --ip #{network}  --netmask 255.255.255.0")
      return vboxnet
    end
    puts "Error:  Failure to configure #{vboxnet} --ip #{network}. "
  else
    puts "Creation of network unsuccesful. #{newnet}"
  end
  nil
end

#############################################################################
require 'yaml'
require 'fileutils'

workingdir = ARGV[0]
testdir    = ARGV[1]
basedir    = __dir__
json_tmp   = File.join(basedir, 'templates', 'simp.json.template')

default_settings = {
  'vm_description'      => 'SIMP-PACKER-BUILD',
  'output_directory'    => "#{testdir}/OUTPUT",
  'nat_interface'       => 'enp0s3',
  'host_only_interface' => 'enp0s8',
  'mac_address'         => 'aabbbbaa0007',
  'firmware'            => 'bios',
  'host_only_gateway'   => '192.168.101.1',
  'domain'              => 'simp.test',
  'puppetname'          => 'puppet',
  'new_password'        => 'P@ssw0rdP@ssw0rd',
  'fips'                => 'fips=0',
  'disk_encrypt'        => '',
  'big_sleep'           => '',
  'headless'            => 'true',
  'iso_dist_dir'        => '/net/ISO/Distribution_ISOs',
  'root_umask'          => '0077'
}

# input packer.yaml and merge with default settings
in_settings = YAML.load_file("#{testdir}/packer.yaml")
settings    = validate_settings(default_settings.merge(in_settings))

# input the sample simp_conf.yaml and update the network
# settings and any settings from the packer.yaml file.
# (Right now this will override the simp_conf.yaml
# with default setting also such as fips and the LDAP
# settings. )
simpconfig = YAML.load_file("#{testdir}/simp_conf.yaml")
# I set the address of the puppet server to 7 in the network.
network     = settings['host_only_gateway'].split('.')[0, 3].join('.')
puppet_fqdn = settings['puppetname'] + '.' + settings['domain']
puppet_ip   = network + '.7'

simpconfig['cli::network::gateway'] = settings['host_only_gateway']
simpconfig['simp_options::dns::servers'] = [puppet_ip]
simpconfig['cli::network::ipaddress'] = puppet_ip
simpconfig['simp_options::puppet::server'] = puppet_fqdn
simpconfig['cli::network::hostname'] = simpconfig['simp_options::puppet::server']
simpconfig['simp_options::puppet::ca'] = simpconfig['simp_options::puppet::server']
simpconfig['cli::network::interface'] = settings['host_only_interface']
simpconfig['cli::network::netmask'] = '255.255.255.0'
simpconfig['simp_options::dns::search'] = [settings['domain']]
simpconfig['simp_options::trusted_nets'] = network + '.0/24'
simpconfig['simp_options::ldap::base_dn'] = 'dc=' + settings['domain'].split('.').join(',dc=')
simpconfig['simp_options::fips'] = settings['fips'].eql?('fips=1')
simpconfig['simp_options::ntpd::servers'] = [simpconfig['cli::network::gateway']]

File.open("#{workingdir}/files/simp_conf.yaml", 'w') do |h|
  h.write simpconfig.to_yaml
  h.close
end

# Get rid of the comments in the simp.json file and copy to the working directory.
json = read_and_strip_comments_from_file json_tmp
File.open("#{workingdir}/simp.json", 'w') do |h|
  h.write json
  h.close
end

# Update the vars.json file with all the settings from packer.conf
# and copy to the working directory
require 'json'

vars_json = File.read("#{testdir}/vars.json")
json_hash = JSON.parse(vars_json)
updated_json_hash = update_hash(json_hash, settings)

File.open("#{workingdir}/vars.json", 'w') do |h|
  h.write(updated_json_hash.to_json)
  h.close
end

top_output = settings['output_directory']
FileUtils.mkdir_p("#{top_output}/testfiles")

# Write out the Vagrantfile + Vagrantfile.erb template
{
  'Vagrantfile'     => 'Vagrantfile.erb',
  'Vagrantfile.erb' => 'vagrantfiles/Vagrantfile.erb.erb'
}.each do |vagrantfile, template_file|
  vfile_contents = Simp::Packer::VagrantfileTemplate.new(
    updated_json_hash['vm_description'],
    simpconfig['cli::network::ipaddress'],
    updated_json_hash['mac_address'],
    updated_json_hash['host_only_network_name'],
    File.read(File.expand_path("templates/#{template_file}", basedir))
  ).render

  vagrantfile_path = File.join top_output, vagrantfile
  FileUtils.mkdir_p(File.dirname(vagrantfile_path))
  File.open(vagrantfile_path, 'w') do |h|
    h.write(vfile_contents)
    h.close
  end
end

# Copy the setup files to the output dir for reference
FileUtils.cp("#{testdir}/vars.json", "#{top_output}/testfiles/vars.json")
FileUtils.cp("#{testdir}/simp_conf.yaml", "#{top_output}/testfiles/simp_conf.yaml")
FileUtils.cp("#{testdir}/packer.yaml", "#{top_output}/testfiles/packer.yaml")
FileUtils.cp("#{workingdir}/vars.json", "#{top_output}/testfiles/workingdir.vars.json")
FileUtils.cp("#{workingdir}/simp.json", "#{top_output}/testfiles/workingdir.simp.json")
