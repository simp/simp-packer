#!/usr/bin/env ruby
#
#This is going to take the files in the test directory and update
#what needs to be updated in the configuration files according
#to the packer.yaml settings and move them to the working directory.
#The working directory is what is copied to simp server.
#

class VagrantFile
  def initialize(dir,name,ip,mac,nw)
    @name = name;
    @ipaddress = ip;
    @mac = mac;
    @nw = nw;
    @template = File.read("#{dir}/templates/Vagrantfile.erb")
  end

  def render
    require 'erb'
    ERB.new(@template).result( binding )
  end
end

class Utils
  def self.encrypt_openldap_hash( string, salt=nil )
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
end

######################################################################
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
    raise "JSON file does not exist or is not a file."
  end
end

#####################################################################

def update_hash(json_hash,settings)
    time = Time.new
    # TODO:  Clean up -This would be a simple loop if I made the variable names
    # in the packer.conf the same as the names in the simp.json
    json_hash['new_password'] = settings['NEW_PASSWORD']
    json_hash['domain'] = settings['DOMAIN']
    json_hash['disk_encrypt'] = settings['DISK_CRYPT']
    json_hash['nat_if'] = settings['NAT_INTERFACE']
    json_hash['vm_description'] = settings['VM_DESCRIPTION']
    json_hash['fips'] = settings['FIPS']
    json_hash['output_directory'] = settings['OUTPUT_DIRECTORY']
    json_hash['mac_address'] = settings['MACADDRESS']
    json_hash['big_sleep'] = settings['BIG_SLEEP']
    json_hash['root_umask'] = settings['ROOT_UMASK']
    json_hash['postprocess_output'] = settings['OUTPUT_DIRECTORY']
    json_hash['output_directory'] = settings['OUTPUT_DIRECTORY'] + "/" + time.strftime("%Y%m%d%H%M")

    json_hash['host_only_network_name'] = getvboxnetworkname(settings['HOST_ONLY_GATEWAY'])
    if json_hash['host_only_network_name'].nil?
       raise "Error: could not create or find a virtualbox network for #{settings['HOST_ONLY_GATEWAY']}"
    end
    return json_hash
end

######################################################################3
def getvboxnetworkname(network)

  vboxnet = nil
  hostonlylist=Hash.new
  name = nil
  ipaddr = nil

# Get the list of virtual box networks
  list=%x(VBoxManage list hostonlyifs).split("\n\n")
  list.each { |x|
    nw=x.split("\n")
    nw.each { |y|
      entry=y.split(":")
      case entry[0]
      when "Name"
        name = entry[1].strip
      when "IPAddress"
        ipaddr = entry[1].strip
      end
    }
    hostonlylist[name] = ipaddr
  }
# Check if the network exists and return it name if it does
  hostonlylist.each {|name, ip|
    if  ip.eql? network
      vboxnet = name
      return vboxnet
    end
  }
# Network does not exists, create it and return the name
  puts "creating new Virtualbox hostonly network for #{network}"
  newnet=%x(VBoxManage hostonlyif create)
  if ( newnet.include? "was successfully created" )
    x = newnet.split("'")
    vboxnet = x[1]
    if system("VBoxManage hostonlyif ipconfig #{vboxnet} --ip #{network}  --netmask 255.255.255.0")
      return vboxnet
    else
      puts "Error:  Failure to configure #{vboxnet} --ip #{network}. "
    end
  else
    puts "Creation of network unsuccesful. #{newnet}"
  end
  return nil
end

#############################################################################
require 'yaml'
require 'fileutils'

workingdir = ARGV[0]
testdir = ARGV[1]
basedir = File.expand_path(File.dirname(__FILE__))
json_tmp = basedir + "/simp.json.template"

default_settings = {
      'VM_DESCRIPTION'      => 'SIMP-PACKER-BUILD',
      'OUTPUT_DIRECTORY'    => "#{testdir}/OUTPUT",
      'NAT_INTERFACE'       => 'enp0s3',
      'HOST_ONLY_INTERFACE' => 'enp0s8',
      'MACADDRESS'          => 'aabbbbaa0007',
      'HOST_ONLY_GATEWAY'   => '192.168.101.1',
      'DOMAIN'              => 'simp.test',
      'PUPPETNAME'          => 'puppet',
      'NEW_PASSWORD'        => 'P@ssw0rdP@ssw0rd',
      'FIPS'                => 'fips=0',
      'DISK_CRYPT'          => '',
      'BIG_SLEEP'           => '',
      'ROOT_UMASK'          => '0077'
}

# input packer.yaml and merge with default settings
in_settings = YAML.load_file("#{testdir}/packer.yaml")
settings = default_settings.merge(in_settings)

# input the sample simp_conf.yaml and update the network
# settings and any settings from the packer.yaml file.
# (Right now this will override the simp_conf.yaml
# with default setting also such as fips and the LDAP
# settings. )
simpconfig = YAML.load_file("#{testdir}/simp_conf.yaml")
# I set the address of the puppet server to 7 in the network.
network = settings['HOST_ONLY_GATEWAY'].split(".")[0,3].join(".")
puppet_fqdn = settings['PUPPETNAME'] + "." + settings['DOMAIN']
puppet_ip = network + ".7"

simpconfig['cli::network::gateway'] = settings['HOST_ONLY_GATEWAY']
simpconfig['simp_options::dns::servers'] = [ puppet_ip ]
simpconfig['cli::network::ipaddress'] = puppet_ip
simpconfig['simp_options::puppet::server'] = puppet_fqdn
simpconfig['cli::network::hostname'] = simpconfig['simp_options::puppet::server']
simpconfig['simp_options::puppet::ca'] = simpconfig['simp_options::puppet::server']
#
simpconfig['cli::network::interface'] = settings['HOST_ONLY_INTERFACE']
simpconfig['cli::network::netmask'] = "255.255.255.0"
simpconfig['simp_options::dns::search'] = [ settings['DOMAIN'] ]
simpconfig['simp_options::trusted_nets']= network + ".0/24"
simpconfig['simp_options::ldap::base_dn'] = "dc=" + settings['DOMAIN'].split(".").join(",dc=")
simpconfig['simp_options::fips'] = settings['FIPS'].eql?("fips=1")
simpconfig['simp_options::ntpd::servers'] = [ simpconfig['cli::network::gateway'] ]

File.open("#{workingdir}/files/simp_conf.yaml",'w') do |h|
     h.write simpconfig.to_yaml
     h.close
end

#Get rid of the comments in the simp.json file and copy to the working directory.
json = getjson json_tmp
File.open("#{workingdir}/simp.json",'w') { |h|
     h.write json
     h.close
}

# Update the vars.json file with all the settings from packer.conf
# and copy to the working directory
require 'json'

file =  File.read("#{testdir}/vars.json")

json_hash = JSON.parse(file)

updated_json_hash = update_hash(json_hash,settings)

File.open("#{workingdir}/vars.json", 'w' ) do |h|
  h.write(updated_json_hash.to_json)
  h.close
end

# Write out the Vagrantfile

erb = VagrantFile.new(basedir,updated_json_hash['vm_description'],simpconfig['cli::network::ipaddress'],updated_json_hash['mac_address'],updated_json_hash['host_only_network_name'])
vfile_contents=erb.render

top_output=settings['OUTPUT_DIRECTORY']
FileUtils.mkdir_p(top_output)

File.open("#{top_output}/Vagrantfile",'w') do |h|
  h.write(vfile_contents)
  h.close
end
