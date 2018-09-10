require 'simp/packer/tests/matrix_unroller'
require 'fileutils'
require 'rake/file_utils'

module Simp
  module Packer
    module Tests
      class Matrix
        include MatrixUnroller
        include FileUtils
        # @param matrix [Array] matrix of things
        def initialize(matrix)
          @iterations = unroll matrix

          @iso_dir = ENV['ISO_DIR'] || "/opt/#{ENV['USER']}/ISO"
          @src_dir = ENV['SRC_DIR'] || "/opt/#{ENV['USER']}/src"
          @box_dir = ENV['BOX_DIR'] || "/opt/#{ENV['USER']}/vagrant"
          @files_dir = ENV['SAMPLE_DIR'] || File.join(
            File.dirname(File.dirname(__FILE__)), 'files'
          )

          @dir_name           = ENV['DIR_NAME']           || 'test'
          @simp_iso_dir       = ENV['SIMP_ISO_DIR']       || File.join(@iso_dir, 'simp', 'prereleases')
          @simp_iso_json_template = ENV['SIMP_ISO_JSON'] || \
                                    File.join(@simp_iso_dir, 'SIMP-6.2.0-RC1.%OS%-CentOS-%OS_MAJ_VER%.?-x86_64.json')
          @packer_configs_dir = ENV['SIMP_PACKER_CONFIGS_DIR'] || File.join(@files_dir, 'configs')
          @tmp_dir            = ENV['TMP_DIR'] || File.join(Dir.pwd, 'tmp')
        end

        def run(label = 'build_' + Time.now.utc.strftime('%Y%m%d_%H%M%S'))
          iteration_total = @iterations.size
          iteration_number = 0
          @iterations.each do |cfg|
            iteration_number += 1
            os         = cfg[:os]
            os_maj_ver = os.sub(%r{^.*(\d+)(?:\.\d+)?$}, '\1')

            # TODO: will eventually need a more robust check for rhel, oel
            os_name    = "centos#{Regexp.last_match(1)}" if os =~ %r{^el([\d])$}
            fips       = (cfg[:fips] || 'on') == 'on'
            encryption = (cfg[:encryption] || 'off') == 'on'
            iteration_dir  = "#{label}__#{os}_#{fips ? 'fips' : 'nofips'}"
            iteration_dir += '_encryption' if encryption
            iteration_summary = "os=#{os} fips=#{fips ? 'on' : 'off'}"
            iteration_summary = ' encryption=on' if encryption

            # FIXME: the pattern matching of the files my not line up with the
            # iteration os.  This workaround uses the .json to find a match
            # based on the os major version number
            resolved_json = matrix_subs(@simp_iso_json_template, os, os_maj_ver)
            simp_iso_json = Dir[resolved_json].select do |x|
              j = JSON.parse(File.read(x))
              j['box_distro_release'] =~ %r{#{os.sub(%r{^el}, 'CentOS-')}}
            end
            if simp_iso_json.size > 1
              raise "Multiple versions found for '#{os}':\n#{simp_iso_json.map { |x| "  - #{x}" }.join("\n")}"
            end
            simp_iso_json = simp_iso_json.first
            vars_data = JSON.parse(File.read(simp_iso_json))

            same_patt = Dir[simp_iso_json.gsub(%r{\.json$}, '.iso')].first
            subbed_env_var = matrix_subs(ENV['SIMP_ISO_FILE'].to_s, os, os_maj_ver)
            if File.file?(subbed_env_var)
              simp_iso_file = subbed_env_var
              vars_data['iso_url'] = simp_iso_file
              warn "INFO: ISO found at ENV['SIMP_ISO_FILE']:\n  Using ISO '#{simp_iso_file}'"
            elsif File.file?(vars_data['iso_url'])
              simp_iso_file = vars_data['iso_url']
              warn "INFO: ISO found at iso_url in '#{simp_iso_json}':\n  Using ISO '#{simp_iso_file}'"
            elsif File.file?(same_patt)
              simp_iso_file = same_patt
              vars_data['iso_url'] = same_patt
              warn "INFO: falling back to ISO at same path/naming scheme as json file:\n  Using ISO '#{simp_iso_file}'"
            end

            vm_description =  "SIMP#{vars_data['box_simp_release']}-#{os_name.upcase}-#{fips ? 'FIPS' : 'NOFIPS'}"
            vm_description += '-ENCRYPTED' if encryption

            puts "\n==== Iteration #{iteration_number}/#{iteration_total}: #{iteration_summary}"
            puts "vm_description:        #{vm_description}"
            puts "DIR_NAME:              #{iteration_dir}"
            puts "SIMP_ISO_FILE:         #{simp_iso_file}"
            puts "SIMP_ISO_JSON:         #{simp_iso_json}"
            puts "PACKER_CONFIGS_DIR:    #{@packer_configs_dir}"

            raise "ERROR: no .iso file at #{simp_iso_file}" unless File.exist?(simp_iso_file)
            raise "ERROR: no .json file at #{simp_iso_json}" unless File.exist?(simp_iso_json)

            # - create a new directory for the simp-packer "test"
            #   - copy the basic config files from a sample directory
            #   - tweak them to match this test parameter
            local_vars_json = nil
            mkdir_p iteration_dir
            Dir.chdir(iteration_dir) do |_dir|
              local_simp_conf_yaml = 'simp_conf.yaml'
              cp File.join(@packer_configs_dir, os_name, 'simp_conf.yaml'), local_simp_conf_yaml
              generate_packer_yaml(vm_description, os_name, fips, encryption)
              local_vars_json = generate_vars_json(vars_data, simp_iso_file)
            end

            log = "#{iteration_dir}.log"
            sh "date > '#{log}'"
            sh %(EXTRA_SIMP_PACKER_ARGS=${EXTRA_SIMP_PACKER_ARGS:--on-error=ask} \\\n\
                 TMP_DIR="#{@tmp_dir}" \\\n\
                 PACKER_LOG=${PACKER_LOG:-1} \\\n\
                 SIMP_PACKER_save_WORKINGDIR=${SIMP_PACKER_save_WORKINGDIR:-yes} \\\n\
                 time bash -e simp_packer_test.sh "#{File.expand_path iteration_dir}" \\\n\
                 |& tee -a "#{log}")

            sh %(rake "vagrant:publish:local["#{@box_dir}",#{local_vars_json},#{File.expand_path("#{iteration_dir}/OUTPUT/#{vm_description}.box", File.dirname(__FILE__))},hardlink] |& tee -a #{log})
            sh "date > '#{log}'"
          end
        end

        def matrix_subs(string, os_shortcode, os_maj_ver)
          string.to_s.gsub('%OS%', os_shortcode).gsub('%OS_MAJ_VER%', os_maj_ver)
        end

        def generate_packer_yaml(vm_description, os_name, fips, encryption)
          local_packer_yaml = 'packer.yaml'
          packer_yaml_lines = File.read(File.join(@packer_configs_dir, os_name, 'packer.yaml')).split(%r{\n})
          packer_yaml_lines.delete_if { |x| x =~ %r{^(disk_encrypt|vm_decription|fips|headless):} }
          packer_yaml_lines << "vm_description: '#{vm_description}'"
          packer_yaml_lines << "fips: 'fips=#{fips ? '1' : '0'}'"
          packer_yaml_lines << "disk_encrypt: 'simp_disk_crypt'" if encryption
          packer_yaml_lines << "disk_encrypt: 'simp_disk_crypt'" if encryption
          packer_yaml_lines << "headless: 'true'"
          File.open(local_packer_yaml, 'w') { |f| f.puts packer_yaml_lines.join("\n") }
          local_packer_yaml
        end

        # modify the local vars.json to build from our SIMP ISO
        def generate_vars_json(vars_data, simp_iso_file)
          require 'json'
          local_vars_json = 'vars.json'
          vars_data['iso_url'] = simp_iso_file
          File.open(local_vars_json, 'w') { |f| f.puts JSON.pretty_generate(vars_data) }
          local_vars_json
        end
      end
    end
  end
end
