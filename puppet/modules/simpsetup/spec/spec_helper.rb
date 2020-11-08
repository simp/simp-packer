# frozen_string_literal: true

# rubocop:disable Style/MixinUsage
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet'
require 'simp/rspec-puppet-facts'
include Simp::RspecPuppetFacts
# rubocop:enable Style/MixinUsage

require 'pathname'

# RSpec Material
fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

default_hiera_config = <<-HIERA
---
:backends:
  - "rspec"
  - "yaml"
:yaml:
  :datadir: "stub"
:hierarchy:
  - "%{custom_hiera}"
  - "%{spec_title}"
  - "%{module_name}"
  - "default"
HIERA

['hieradata', 'modules'].each do |dir|
  f_dir = File.join(fixture_path, dir)
  FileUtils.mkdir_p(f_dir) unless File.directory?(f_dir)
end

def massage_os_facts(os_facts)
  massaged_facts = os_facts.merge({ networking: {
    'ip'         => os_facts[:ipaddress],
    'fqdn'       => os_facts[:fqdn],
    'domain'     => os_facts[:domain],
    'primary'    => 'ens3',
    'interfaces' => {
      'ens3' => {
        'ip'  => os_facts[:ipaddress],
        'mac' => os_facts[:macaddress]
      }
    }
  } })
  massaged_facts
end

RSpec.configure do |c|
  # If nothing else...
  c.default_facts = {
    production: {
      #:fqdn           => 'production.rspec.test.localdomain',
      path: '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
      concat_basedir: '/tmp'
    }
  }

  c.mock_framework = :rspec
  c.mock_with :mocha

  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.hiera_config = File.join(fixture_path, 'hieradata', 'hiera.yaml')

  # Useless backtrace noise
  backtrace_exclusion_patterns = [%r{spec_helper}, %r{gems}]

  if c.respond_to?(:backtrace_exclusion_patterns)
    c.backtrace_exclusion_patterns = backtrace_exclusion_patterns
  elsif c.respond_to?(:backtrace_clean_patterns)
    c.backtrace_clean_patterns = backtrace_exclusion_patterns
  end

  # rubocop:disable RSpec/BeforeAfterAll
  c.before(:all) do
    data = YAML.safe_load(default_hiera_config, [Symbol])
    data[:yaml][:datadir] = File.join(fixture_path, 'hieradata')

    File.open(c.hiera_config, 'w') do |f|
      f.write data.to_yaml
    end
  end
  # rubocop:enable RSpec/BeforeAfterAll

  c.before(:each) do
    @spec_global_env_temp = Dir.mktmpdir('simpspec')

    if defined?(environment)
      FileUtils.mkdir_p(File.join(@spec_global_env_temp, environment.to_s))
    end

    # ensure the user running these tests has an accessible environmentpath
    Puppet[:environmentpath] = @spec_global_env_temp
    Puppet[:user] = Etc.getpwuid(Process.uid).name
    Puppet[:group] = Etc.getgrgid(Process.gid).name
  end

  c.after(:each) do
    FileUtils.rm_rf(@spec_global_env_temp) # clean up the mocked environmentpath
    @spec_global_env_temp = nil
  end
end

Dir.glob("#{RSpec.configuration.module_path}/*").each do |dir|
  begin
    Pathname.new(dir).realpath
  rescue StandardError
    raise "ERROR: The module '#{dir}' is not installed. Tests cannot continue."
  end
end
