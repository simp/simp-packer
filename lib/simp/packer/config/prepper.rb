# frozen_string_literal: true

require 'simp/packer/config/vagrantfile_writer'
require 'simp/packer/config/vbox_net_utils'
require 'simp/packer/config/simpjsonfile_writer'
require 'json'
require 'yaml'
require 'fileutils'

module Simp
  module Packer
    module Config
      # Update config files with packer.yaml setting and copy to working dir
      #
      #   This is going to take the files in the test directory and update what needs
      #   to be updated in the configuration files according to the packer.yaml
      #   settings and move them to the working directory.  The working directory is
      #   what is copied to simp server.
      #
      class Prepper
        attr_accessor :verbose

        include Simp::Packer::Config::VBoxNetUtils

        def initialize(workingdir, testdir, basedir = File.expand_path("#{__dir__}/../../.."))
          @workingdir = workingdir
          @testdir    = testdir
          @basedir    = basedir
          @verbose    = false
        end

        # Returns a Hash of default `packer.yaml` settings
        # @return [Hash] Default `packer.yaml` settings
        def default_settings
          {
            'big_sleep' => '',
            'bootcmd' => 'simp',
            'disk_encrypt' => 'true',
            'domain' => 'simp.test',
            'fips' => 'fips=0',
            'firmware' => 'bios',
            'headless' => 'true',
            'host_only_gateway' => '192.168.101.1',
            'host_only_interface' => 'enp0s8',
            'iso_dist_dir' => '/net/ISO/Distribution_ISOs',
            'mac_address' => 'aabbbbaa0007',
            'nat_interface' => 'enp0s3',
            'new_password' => 'P@ssw0rdP@ssw0rd',
            'output_directory' => "#{@testdir}/OUTPUT",
            'puppetname' => 'puppet',
            'root_umask' => '0077',
            'simpenvironment' => 'production',
            'ssh_agent_auth' => 'false',
            'vm_description' => 'SIMP-PACKER-BUILD'
          }
        end

        # Remove all the comments from a json template file
        def self.read_and_strip_comments_from_file(json_file)
          unless File.file?(json_file)
            raise "\n\nERROR: JSON file '#{json_file}' does not exist or is not a file."
          end

          f = File.open(json_file, 'r')
          json = ''
          f.each do |line|
            json += line unless line.to_s =~ %r{^(\s*(#|//))}
          end
          f.close
          json
        end

        def sanitize_settings(settings)
          sanitized = settings.dup
          case settings['firmware']
          when 'bios', 'efi'
            sanitized['firmware'] = settings['firmware']
          else
            sanitized['firmware'] = 'bios'
          end

          case settings['headless']
          when %r{[Yy][Ee][Ss]}, true, 'true', %r{[Yy]}
            sanitized['headless'] = 'true'
          when %r{[Nn][Oo]?}, 'false', false
            sanitized['headless'] = 'false'
          else
            sanitized['headless'] = 'true'
            puts "Invalid setting for Headless #{settings['headless']} using 'true'"
          end

          case settings['bootcmd']
          when 'linux-min'
            raise 'ERROR:  linux-min does not work yet'
            # TODO
            # sanitized['bootcmd'] = 'linux-min'
          else
            sanitized['bootcmd'] = 'simp'
          end

          case settings['disk_encrypt']
          when 'simp-nocrypt', 'false', 'no', ''
            sanitized['disk_encrypt'] = 'false'
          else
            # default to encrypt
            sanitized['disk_encrypt'] = 'true'
          end

          sanitized
        end

        # Update the vars.json file with the settings from packer.yaml
        # @return [Hash] Updated vars data
        def configure_vars(vars_data, settings)
          time = Time.new
          vars_data = vars_data.merge(settings)
          vars_data['postprocess_output'] = settings['output_directory']
          vars_data['ssh_agent_auth'] = settings['ssh_agent_auth']
          vars_data['output_directory'] = settings['output_directory'] + '/' + time.strftime('%Y%m%d%H%M')
          vars_data['host_only_network_name'] = vboxnet_for_network(settings['host_only_gateway'])
          if vars_data['host_only_network_name'].nil?
            raise "ERROR: could not create or find a virtualbox network for #{settings['host_only_gateway']}"
          end

          vars_data
        end

        # Construct a complete simp_conf.yaml data structure from settings
        #
        #   This includes:
        #   * correct network settings for the VM
        #   * settings from simp-packer's packer.yaml
        #
        #   The data returned can be used to populate `simp_conf.yaml`
        #
        # @note This will override the original `simp_conf.yaml`'s settings
        #   for thigns like fips and LDAP.
        #
        # @param [Hash] settings     simp-packer settings
        # @param [Hash] simp_config  simp_conf data (or partial data)
        def configure_simp_conf(settings, simp_conf)
          # I set the address of the puppet server to 7 in the network.
          network      = settings['host_only_gateway'].split('.')[0, 3].join('.')
          puppet_fqdn  = settings['puppetname'] + '.' + settings['domain']
          puppet_ip    = network + '.7'
          ldap_base_dn = 'dc=' + settings['domain'].split('.').join(',dc=')

          simp_conf.merge(
            'cli::network::gateway' => settings['host_only_gateway'],
            'simp_options::dns::servers' => [puppet_ip],
            'cli::network::ipaddress' => puppet_ip,
            'simp_options::puppet::server' => puppet_fqdn,
            'cli::network::hostname' => puppet_fqdn,
            'simp_options::puppet::ca' => puppet_fqdn,
            'cli::network::interface' => settings['host_only_interface'],
            'cli::network::netmask' => '255.255.255.0',
            'simp_options::dns::search' => [settings['domain']],
            'simp_options::trusted_nets' => network + '.0/24',
            'simp_options::ldap::base_dn' => ldap_base_dn,
            'simp_options::fips' => settings['fips'].eql?('fips=1'),
            'simp_options::ntpd::servers' => [settings['host_only_gateway']],
          )
        end

        # @param [Hash]   settings   simp-packer settings
        # @param [String] src_file   Path to initial vars.json file
        # @param [String] dest_file  Path to write updated vars.json file
        # @return [Hash]  Updated vars data
        def generate_vars_json(
          settings,
          src_file = "#{@testdir}/vars.json",
          dest_file = "#{@workingdir}/vars.json"
        )
          json = File.read(src_file)
          base_data = JSON.parse(json)
          data = configure_vars(base_data, settings)
          File.open(dest_file, 'w') do |f|
            f.write JSON.pretty_generate(data)
            f.close
          end
          data
        end

        # @param [Hash]   settings   simp-packer settings
        # @param [String] src_file   Path to initial simp_conf.yaml file
        # @param [String] dest_file  Path to write updated simp_conf.yaml file
        # @return [Hash]  Updated simp_conf data
        def generate_simp_conf_yaml(
          settings,
          src_file = "#{@testdir}/simp_conf.yaml",
          dest_file = "#{@workingdir}/files/simp_conf.yaml"
        )
          data = configure_simp_conf(settings, YAML.load_file(src_file))
          File.open(dest_file, 'w') do |f|
            f.write(data.to_yaml)
            f.close
          end
          data
        end

        # Get rid of the comments in the simp.json file and copy to the working directory.
        def generate_simp_json(settings, template_name, basedir, simp_json)
          File.open(simp_json, 'w') do |f|
            f.write Simp::Packer::Config::SimpjsonfileWriter.new(settings, basedir).render template_name
            f.close
          end
        end

        def infer_os_from_name(name)
          name.match(%r{(?<os>CentOS)-(?<el>\d+)})
        end

        # Generate files
        #   - <workingdir>/simp.json
        #   - <workingdir>/simp_conf.yaml
        def generate_files(settings)
          simpconfig_data = generate_simp_conf_yaml(settings)
          vars_data = generate_vars_json(settings)
          # need to know the os_ver if firmware is efi
          # might want to put this in vars.json so we don't have to guess
          settings['os_ver'] = infer_os_from_name(File.basename(vars_data['iso_url']))[:el]
          generate_simp_json(settings, 'simp.json.erb', @basedir, "#{@workingdir}/simp.json")
          generate_vagrantfiles(vars_data, simpconfig_data, settings['output_directory'])
        end

        # Write out box-specific Vagrantfile + Vagrantfile.erb files
        def generate_vagrantfiles(vars_data, simpconfig_data, top_output)
          {
            'Vagrantfile' => 'Vagrantfile.erb',
            'Vagrantfile.erb' => 'vagrantfiles/Vagrantfile.erb.erb'
          }.each do |vagrantfile, template_file|
            vfile_contents = Simp::Packer::Config::VagrantfileWriter.new(
              vars_data['vm_description'],
              simpconfig_data['cli::network::ipaddress'],
              vars_data['mac_address'],
              vars_data['host_only_network_name'],
              File.read(File.expand_path("templates/#{template_file}", @basedir)),
            ).render

            vagrantfile_path = File.join top_output, vagrantfile
            FileUtils.mkdir_p(File.dirname(vagrantfile_path), verbose: @verbose)
            File.open(vagrantfile_path, 'w') do |h|
              h.write(vfile_contents)
              h.close
            end
          end
        end

        def copy_output_files(settings)
          output_dir = settings['output_directory']
          FileUtils.mkdir_p("#{output_dir}/testfiles", verbose: @verbose)

          # Copy the setup files to the output dir for reference
          FileUtils.cp("#{@testdir}/vars.json", "#{output_dir}/testfiles/vars.json", verbose: @verbose)
          FileUtils.cp("#{@testdir}/simp_conf.yaml", "#{output_dir}/testfiles/simp_conf.yaml", verbose: @verbose)
          FileUtils.cp("#{@testdir}/packer.yaml", "#{output_dir}/testfiles/packer.yaml", verbose: @verbose)
          FileUtils.cp("#{@workingdir}/vars.json", "#{output_dir}/testfiles/workingdir.vars.json", verbose: @verbose)
          FileUtils.cp("#{@workingdir}/simp.json", "#{output_dir}/testfiles/workingdir.simp.json", verbose: @verbose)
        end

        def run
          # input packer.yaml and merge with default settings
          in_settings = YAML.load_file("#{@testdir}/packer.yaml")
          settings    = sanitize_settings(default_settings.merge(in_settings))
          generate_files(settings)
          copy_output_files(settings)
        end
      end
    end
  end
end
