require 'simp/packer/build/matrix_unroller'
require 'simp/packer/build/runner'
require 'fileutils'
require 'rake/file_utils'

module Simp
  module Packer
    module Build
      # Run a matrix of simp-packer builds
      class Matrix
        include MatrixUnroller
        include FileUtils

        # @param matrix [Array] matrix of things
        def initialize(matrix)
          env_json_files    = parse_glob_list(ENV['SIMP_ISO_JSON_FILES'])
          matrix_json_files = matrix.select { |x| x =~ %r{^json=} }.map { |x| parse_glob_list(x.sub(%r{^json=}, '')) }.flatten
          json_str          = "json=#{(env_json_files + matrix_json_files).uniq.join(':')}"
          full_matrix       = [json_str] + matrix.delete_if { |x| x =~ %r{^json=} }
          @iterations          = simp_json_iteration_filter(unroll(full_matrix))

          files_dir            = ENV['SAMPLE_DIR'] || File.join(
            File.dirname(File.dirname(__FILE__)), 'files'
          )
          @packer_configs_dir  = ENV['SIMP_PACKER_CONFIGS_DIR'] || File.join(files_dir, 'configs')

          @vagrant_box_dir     = ENV['VAGRANT_BOX_DIR'] || "/opt/#{ENV['USER']}/vagrant"
          @tmp_dir             = ENV['TMP_DIR'] || File.join(Dir.pwd, 'tmp')
          @dir_name            = ENV['DIR_NAME'] || 'test'
        end

        # - list of paths or path globs to SIMP ISO .json files
        # - delimited by `:` or `,`
        # - Non-existent paths will be discarded with a warning message
        def parse_glob_list(str)
          globs = str.split(%r{[,:]})
          list = []
          globs.each do |glob|
            files = Dir[glob]
            if files.empty?
              warn "WARNING: '#{glob}' did not match any files; discarding"
              next
            end
            list += files
          end
          list
        end

        def run(label = (ENV['MATRIX_LABEL'] || 'build') + Time.now.utc.strftime('_%Y%m%d_%H%M%S'))
          iteration_total = @iterations.size
          iteration_number = 0
          @iterations.each do |cfg|
            iteration_number += 1
            simp_iso_json = cfg[:json]
            vars_data     = JSON.parse(File.read(simp_iso_json))
            m             = infer_os_from_name(File.basename(vars_data['iso_url']))

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

            iteration_dir  = "#{label}__#{vars_data['box_simp_release']}__#{os_name}_#{fips ? 'fips' : 'nofips'}"
            iteration_dir += '_encryption' if encryption
            iteration_summary = "os=#{os_name} fips=#{fips ? 'on' : 'off'}"
            iteration_summary = ' encryption=on' if encryption
            vm_description =  "SIMP#{vars_data['box_simp_release']}-#{os_name.upcase}-#{fips ? 'FIPS' : 'NOFIPS'}"
            vm_description += '-ENCRYPTED' if encryption

            msg = []
            msg << "\n" * 5
            msg << '=' * 80
            msg << "==== Iteration #{iteration_number}/#{iteration_total}: #{vars_data['box_simp_release']} #{iteration_summary}"
            msg << '=' * 80
            msg << "vm_description:        #{vm_description}"
            msg << "DIR_NAME:              #{iteration_dir}"
            msg << "SIMP_ISO_FILE:         #{simp_iso_file}"
            msg << "SIMP_ISO_JSON:         #{simp_iso_json}"
            msg << "PACKER_CONFIGS_DIR:    #{@packer_configs_dir}"
            msg << '=' * 80
            msg << "\n" * 2
            msg << ''
            iterator_header_msg = msg.join("\n")
            puts iterator_header_msg

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
            packer_build_runner = Simp::Packer::Build::Runner.new(
              File.expand_path(iteration_dir)
            )

            File.open(log, 'a') { |f| f.puts iterator_header_msg }
            packer_build_runner.run(
              log_file: log,
              tmp_dir:  @tmp_dir,
              extra_packer_args: ENV['SIMP_PACKER_extra_args'] || '--on-error=ask'
            )
            cmd = %(set -e; set -o pipefail; \\\n\
                 SIMP_PACKER_save_WORKINGDIR=${SIMP_PACKER_save_WORKINGDIR:-yes} \\\n\
                 time bash -e simp_packer_test.sh "#{File.expand_path iteration_dir}" \\\n\
                 |& tee -a "#{log}")
            puts '-' * 80, cmd, '-' * 80
            sh cmd

            new_box = File.expand_path("#{iteration_dir}/OUTPUT/#{vm_description}.box")
            vars_json_path = File.expand_path(local_vars_json, iteration_dir)

            Simp::Packer::Publish::LocalDirTree.publish(vars_json_path, new_box, @vagrant_box_dir)
            sh "date >> '#{log}'"
          end
        end

        def generate_packer_yaml(vm_description, os_name, fips, encryption)
          local_packer_yaml = 'packer.yaml'
          packer_yaml_lines = File.read(File.join(@packer_configs_dir, os_name, 'packer.yaml')).split(%r{\n})
          packer_yaml_lines.delete_if { |x| x =~ %r{^(disk_encrypt|vm_decription|fips|headless):} }
          packer_yaml_lines << "vm_description: '#{vm_description}'"
          packer_yaml_lines << "fips: 'fips=#{fips ? '1' : '0'}'"
          packer_yaml_lines << "headless: 'true'"
          if encryption
            packer_yaml_lines << "disk_encrypt: 'simp_disk_crypt'"
            packer_yaml_lines.select { |x| x =~ %r{^big_sleep} }.each { |x| x.sub!('<wait10>', '<wait10>' * 12) }
          end
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

        # Filter unrolled matrix down to iterations with valid SIMP ISO json
        #   files that match their os
        def simp_json_iteration_filter(unrolled_matrix)
          json_data = actual_json_files(unrolled_matrix.map { |c| c[:json] }.uniq)
          unrolled_matrix.select do |i|
            next unless json_data.key?(i[:json])
            el = i[:os].sub(%r{^el}, '')
            puts "el = '#{el}'"
            iso_name = File.basename(json_data[i[:json]]['iso_url'])
            puts "iso_name = '#{iso_name}'"
            infer_os_from_name(iso_name)[:el] == el
          end
        end

        def actual_json_files(json_files)
          files = {}
          json_files.each do |f|
            begin
              files[f] = JSON.parse(File.read(f))
            rescue Errno::ENOENT
              warn("WARNING: File not found: '#{f}'")
            rescue JSON::ParserError
              warn("WARNING: Not a JSON file: '#{f}'")
            end
          end
          files
        end

        def infer_os_from_name(name)
          name.match(%r{(?<os>CentOS)-(?<el>\d+)})
        end
      end
    end
  end
end
