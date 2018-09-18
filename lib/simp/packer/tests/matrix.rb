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
          simp_iso_json_files = ENV['SIMP_ISO_JSON_FILES']
          @simp_iso_json_files = simp_iso_json_files.split(%r{[,:]})
          full_matrix = ["json=#{@simp_iso_json_files.join(':')}"] + matrix
          @iterations = simp_json_filter(unroll(full_matrix))
          @box_dir = ENV['VAGRANT_BOX_DIR'] || "/opt/#{ENV['USER']}/vagrant"
          @files_dir = ENV['SAMPLE_DIR'] || File.join(
            File.dirname(File.dirname(__FILE__)), 'files'
          )

          @dir_name           = ENV['DIR_NAME'] || 'test'
          @packer_configs_dir = ENV['SIMP_PACKER_CONFIGS_DIR'] || File.join(@files_dir, 'configs')
          @tmp_dir            = ENV['TMP_DIR'] || File.join(Dir.pwd, 'tmp')
        end

        def run(label = (ENV['MATRIX_LABEL'] || 'build') + Time.now.utc.strftime('_%Y%m%d_%H%M%S'))
          iteration_total = @iterations.size
          iteration_number = 0
          @iterations.each do |cfg|
            iteration_number += 1
            simp_iso_json = cfg[:json]
            vars_data = JSON.parse(File.read(simp_iso_json))
            m = infer_os_from_name(File.basename(vars_data['iso_url']))

            os         = cfg[:el]
            os_name    = "#{m[:os]}#{m[:el]}".downcase
            fips       = (cfg[:fips] || 'on') == 'on'
            encryption = (cfg[:encryption] || 'off') == 'on'

            same_patt = Dir[simp_iso_json.gsub(%r{\.json$}, '.iso')].first
            if File.file?(vars_data['iso_url'])
              simp_iso_file = vars_data['iso_url']
              warn "INFO: ISO found at iso_url in '#{simp_iso_json}':\n  Using ISO '#{simp_iso_file}'"
            elsif File.file?(same_patt)
              simp_iso_file = same_patt
              vars_data['iso_url'] = same_patt
              warn "INFO: falling back to ISO at same path/naming scheme as json file:\n  Using ISO '#{simp_iso_file}'"
            end

            iteration_dir  = "#{label}__#{vars_data['box_simp_release']}__#{os}_#{fips ? 'fips' : 'nofips'}"
            iteration_dir += '_encryption' if encryption
            iteration_summary = "os=#{os} fips=#{fips ? 'on' : 'off'}"
            iteration_summary = ' encryption=on' if encryption
            vm_description =  "SIMP#{vars_data['box_simp_release']}-#{os_name.upcase}-#{fips ? 'FIPS' : 'NOFIPS'}"
            vm_description += '-ENCRYPTED' if encryption

            puts "\n" * 5
            puts '=' * 80
            puts "==== Iteration #{iteration_number}/#{iteration_total}: #{vars_data['box_simp_release']} #{iteration_summary}"
            puts '=' * 80
            puts "vm_description:        #{vm_description}"
            puts "DIR_NAME:              #{iteration_dir}"
            puts "SIMP_ISO_FILE:         #{simp_iso_file}"
            puts "SIMP_ISO_JSON:         #{simp_iso_json}"
            puts "PACKER_CONFIGS_DIR:    #{@packer_configs_dir}"
            puts '=' * 80
            puts "\n" * 2

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

            new_box = File.expand_path("#{iteration_dir}/OUTPUT/#{vm_description}.box")
            vars_json_path = File.expand_path(local_vars_json, iteration_dir)
            sh %(rake vagrant:publish:local["#{@box_dir}","#{vars_json_path}","#{new_box}",hardlink] |& tee -a #{log})
            sh "date >> '#{log}'"
          end
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

        def simp_json_filter(unrolled_matrix)
          json_files = unrolled_matrix.map { |c| c[:json] }.uniq
          actual_json_files = {}
          json_files.each do |f|
            begin
              actual_json_files[f] = JSON.parse(File.read(f))
            rescue Errno::ENOENT
              warn("WARNING: File not found: '#{f}'")
            rescue JSON::ParserError
              warn("WARNING: Not a JSON file: '#{f}'")
            end
          end

          filtered_matrix = unrolled_matrix.select { |x| actual_json_files.key?(x[:json]) }
          filtered_matrix.select do |cfg|
            iso_name = File.basename(actual_json_files[cfg[:json]]['iso_url'])
            infer_os_from_name(iso_name)[:el] == cfg[:el]
          end
        end

        def infer_os_from_name(name)
          name.match(%r{(?<os>CentOS)-(?<el>\d+)})
        end
      end
    end
  end
end
