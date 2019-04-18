#! /usr/bin/env ruby
require 'yaml'

class SettingsError < StandardError; end

class CheckSettings
  def initialize(never_fail)
    # when true, checking stops at the first failed
    # check, but the failure is ignored
    @never_fail = never_fail
  end

  # Verifies that the system hiera setting for FIPS and the actual
  # FIPS mode match the test setting.  The check for the system
  # hiera setting verifies that 'simp config' sets the hiera value
  # to match the current FIPS mode.
  def check_fips_mode
    expected_conf = @expected_conf['simp_options::fips']
    actual_conf = @actual_conf['simp_options::fips']

    if actual_conf == expected_conf
      # get the actual system setting of fips
      fips = IO.read('/proc/sys/crypto/fips_enabled').to_i
      fips_enabled = (fips == 1)

      if fips_enabled == expected_conf
        puts "The system fips setting '#{fips}' and configuration" \
             " setting '#{expected_conf}' agree."
      else
        err_msg = "System setting fips = #{fips} does not agree with" \
                  " configuration setting '#{expected_conf}'."
        raise SettingsError, err_msg
      end
    else
      err_msg = "Expected FIPs configuration is '#{expected_conf}' but" \
                " the actual configuration has '#{actual_conf}'."
      raise SettingsError, err_msg
    end
  end

  # Verifies that puppet is operating with the SIMP default for the
  # masterport and the test configured ca_port.
  def check_puppet_ports
    # Currently, the default values of pupmod::master::masterport is
    # not modified by any tests.  So, the masterport should be 8410,
    # instead of the default of 8150.
    # TODO read configured value from the hieradata
    expected = 8140
    actual = %x(puppet config print masterport).to_i

    if actual == expected
      puts "The puppet masterport setting matches the configured value '#{expected}'."
    else
      err_msg = "Puppet master port should be '#{expected}', but is set to #{actual}."
      raise SettingsError, err_msg
    end

    # For the test configuration, the puppet master is also the CA server.
    expected = @expected_conf['simp_options::puppet::ca_port']
    actual = %x(puppet config print ca_port).to_i

    if actual == expected
      puts "The puppet ca_port setting matches the configured value '#{expected}'."
    else
      err_msg =  "The puppet ca_port setting should be '#{expected}'," \
                 " but is '#{actual}'."
      raise SettingsError, err_msg
    end
  end

  # Verifies that the puppetserver and puppetdb services are running.
  def check_puppet_services_running
    check_service_status('puppetserver', 'running')
    check_service_status('puppetdb', 'running')
  end

  # Verifies that the system is set to the SIMP default for selinux mode.
  def check_selinux
    # Currently, the default values of simp_options::selinux or
    # selinux::ensure are not modified by any tests.  So, selinux
    # should be 'Enforcing'.
    # TODO read configured value from the hieradata
    expected = 'Enforcing'
    actual = %x(/usr/sbin/getenforce).strip
    if actual == expected
      puts "The system selinux setting agrees with the configured value '#{expected}'."
    else
      err_msg = "Selinux should be '#{expected}', but is set to '#{actual}'."
      raise SettingsError, err_msg
    end
  end

  # Verifies that the named service has the expected status.
  # The expected status should be 'running' or 'stopped', which
  # are the 'ensure' values returned by
  #   puppet resource service <service name>
  def check_service_status(service, expected_status = 'running')
    result = %x(puppet resource service #{service})
    match = result.match(%r{ensure => '(stopped|running)',})
    if match
      if match[1] == expected_status
        puts "Service '#{service}' status matches expected value '#{expected_status}'."
      else
        err_msg = "Service '#{service}' status should be '#{expected_status}'," \
                  " but is '#{match[1]}'."
        raise SettingsError, err_msg
      end
    else
      # even if the service doesn't exist, the puppet CLI will return
      #  service { '<service name>':
      #    ensure => 'stopped',
      #    enable => 'false'
      #   }
      # So we must really be broken, if the puppet CLI doesn't work!
      err_msg = "Unable to determine #{service} status using 'puppet resource service'."
      raise SettingsError, err_msg
    end
  end

  def execute_checks
    check_fips_mode
    check_selinux
    check_puppet_services_running
    check_puppet_ports
  end

  # Loads the test and actual settings from their respective files,
  # packer.yaml and (typically) simp_config_settings.yaml
  def load_settings
    @expected_conf = YAML.load_file(@expected_conf_file)
    @actual_conf = YAML.load_file(@actual_conf_file)
  end

  def parse_args(_args)
    if ARGV.size < 2
      msg = "Usage: #{File.basename(__FILE__)} expected_conf_file actual_conf_file"
      raise ArgumentError, msg
    end
    @expected_conf_file = ARGV[0] # test config (packer.yaml)
    @actual_conf_file = ARGV[1]   # actual config on server under test
    # (simp_config_settings.yaml)
  end

  # Load the configuration specified by command line arguments
  # and then execute the checks
  def run(args)
    begin
      parse_args(args)
      load_settings

      execute_checks
      result = 0
    rescue SettingsError => e
      # check failure
      if @never_fail
        puts "Settings error ignored: #{e.message}"
        result = 0
      else
        warn "ERROR: #{e.message}"
        result = 1
      end
    rescue ArgumentError, Psych::SyntaxError => e
      # YAML parsing error
      warn "ERROR: #{e.message}"
      result = 1
    rescue StandardError => e
      # everything else
      warn "FAILURE: #{e.message}"
      e.backtrace.first(10).each { |l| warn l }
      result = 1
    end

    result
  end
end

###########################################################
# To ignore validation failures, thereby allowing the Packer
# build to continue to run, set never_fail to true.  This is
# useful if you want to allow the box to be built so you can get
# onto the box to debug a validation failure.
#
# TODO: Make this a packer.yaml setting and apply to all validation
#       scripts
###########################################################
never_fail = false

if $PROGRAM_NAME == __FILE__
  checker = CheckSettings.new(never_fail)
  exit checker.run(ARGV)
end
