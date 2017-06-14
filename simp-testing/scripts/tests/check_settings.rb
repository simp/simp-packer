#! /usr/bin/env ruby
require 'yaml'

class SettingsError < StandardError; end

simp_conf_yaml = ARGV[0]
simp_settings = ARGV[1]

# To continue to run even if a validation fails, set never_fail to true.
# This is useful if you want to allow the box to be built so you can get
# onto the box to debug a validation failure.
never_fail = false

begin

  settings=YAML.load_file("#{simp_settings}")
  conf=YAML.load_file("#{simp_conf_yaml}")
  # get the actual system setting of fips
  fips=IO.read('/proc/sys/crypto/fips_enabled').to_i
  fips_enabled = (fips == 1)

  #Get the setting from the simp_conf.yaml files
  fips_conf=conf['simp_options::fips']
  #Get the setting from Hiera yaml file
  fips_settings=settings['simp_options::fips']

  if fips_conf == fips_settings
   
    if fips_enabled == fips_conf
      puts "The system setting fips = #{fips} and configuration setting #{fips_conf} agree."
    else
      raise SettingsError.new("Error: System setting fips = #{fips} and configuration files say fips = #{fips_conf}.")
    end
  else
    raise SettingsError.new("Error: Setting in the simp_conf.yaml file for simp_cli is #{fips_conf} but the simp_config_setting.yaml file has #{fips_settings}.")
  end

  selinux=%x(/usr/sbin/getenforce).strip

  # TODO read this value from the settings and then compare expected to
  # (mapped) actual
  if selinux == 'Enforcing'
    puts 'The system selinux setting agrees with configuration file'
  else
    raise SettingsError.new("Error: Selinux should be Enforcing, but is set to #{selinux}.")
  end

  #
  # Check the ports.
  # SIMP configures master port for 8140.  It should be set to that not the default 8150
  masterport = %x(puppet config print masterport).to_i

  if masterport != 8140
    raise SettingsError.new("Error: Master port is not 8140 it is #{masterport}.")
  end

  # This assumes this server is also the ca server.  Can put a check in for
  # this later.
  ca_port = %x(puppet config print ca_port).to_i
  ca_port_setting = conf['simp_options::puppet::ca_port']

  if ca_port != ca_port_setting
    raise SettingsError.new("Error: The ca_port setting in simp_conf file #{ca_port_setting} does not equal puppet ca_port #{ca_port}.")
  end

rescue SettingsError =>e
  if never_fail
    puts "Settings error ignored: #{e.message}"
  else
    raise(e)
  end
end

exit(0)
