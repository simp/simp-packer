#! /usr/bin/env ruby
require 'yaml'

simp_conf_yaml = ARGV[0]
simp_settings = ARGV[1]


settings=YAML.load_file("#{simp_settings}")
conf=YAML.load_file("#{simp_conf_yaml}")
# get the actual system setting of fips
pfips=File.open('/proc/sys/crypto/fips_enabled')
fips=pfips.sysread(1)


#Get the setting from the simp_conf.yaml files
fips_conf=conf['simp_options::fips']
#Get the setting from Hiera yaml file
fips_settings=['simp_options::fips']

if fips_conf == fips_settings
  case fips
  when 0
    if fips_conf
      raise "Error: System setting fips = #{fips} and configuration files say fips = #{fips_conf}"
    else
      puts "The system setting fips = #{fips} and configuration setting #{fips_conf} agree."
    end
  when 1
    if ! fips_conf
      raise "Error: System setting fips = #{fips} and configuration files say fips = #{fips_conf}."
    else
      puts "The system setting, fips = #{fips}, and configuration setting, #{fips_conf}, agree"
    end

  else
    raise "Error: Got garbage from /proc/sys/crypto/fips-enable:  #{fips} (should be 0 or 1)."
  end
else
  raise "Error: Setting in the simp_conf.yaml file for simp_cli is #{fips_conf} but the simp_config_setting.yaml file has #{fips_settings}."
end

selinux=%x(getenforce)

if selinux != 'Enforcing'
  raise "Error: Selinux should default to Enforcing is set to #{selinux}."
end

#
# Check the ports.
# SIMP configures master port for 8140.  It should be set to that not the default 8150
masterport = %x(puppet config print masterport)

if masterport != '8140'
  raise "Error: Master port is not 8140 it is #{masterport}."
end

# This assumes this server is also the ca server.  Can put a check in for
# this later.
ca_port = %x(puppet config print ca_port)
ca_port_setting = conf['simp_options::puppet::ca_port']

if ca_port != ca_port_setting
  raise "Error: The ca_port setting in simp_conf file #{ca_port_setting} does not equal puppet ca_port #{ca_port}."
end
