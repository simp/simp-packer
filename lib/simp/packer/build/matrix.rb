# frozen_string_literal: true

require 'simp/tests/matrix/unroller'
require 'simp/packer/build/runner'
require 'simp/packer/vars_json'
require 'fileutils'
require 'rake/file_utils'
require 'pry'
require 'pry-byebug'

module Simp
  module Packer
    module Build
      # Run a matrix of simp-packer builds/
      class Matrix
        include Simp::Tests::Matrix::Unroller
        include FileUtils

        DEFAULT_OPTS = {
          simp_iso_json_files: ENV['SIMP_ISO_JSON_FILES'] || '',
          simp_packer_configs_dir: ENV['SIMP_PACKER_CONFIGS_DIR'] || File.expand_path('../files/configs', __dir__),
          vagrant_box_dir: ENV['VAGRANT_BOX_DIR'] || "/opt/#{ENV['USER']}/vagrant",
          base_dir: Dir.pwd,
          tmp_dir: ENV['TMP_DIR'] || File.join(Dir.pwd, 'tmp'),
          dry_run: (ENV['SIMP_PACKER_dry_run'] || 'no') == 'yes',
          extra_packer_args: ENV['SIMP_PACKER_extra_args'] || nil
        }.freeze

        # @param matrix [Array] matrix of things
        def initialize(matrix, opts = {})
          @opts = DEFAULT_OPTS.merge(opts)

          # SIMP ISO json list/glob come from opts and/or `json=` in the matrix
          env_json_files      = parse_glob_list(@opts[:simp_iso_json_files])
          matrix_json_files   = matrix.select { |x| x =~ %r{^json=} }.map { |x|
            parse_glob_list(x.sub(%r{^json=}, ''))
          }.flatten
          json_str            = "json=#{(env_json_files + matrix_json_files).uniq.join(':')}"
          full_matrix         = [json_str] + matrix.delete_if { |x| x =~ %r{^json=} }
          @iterations         = iterations_with_valid_simp_json(unroll(full_matrix))
          @packer_configs_dir = @opts[:simp_packer_configs_dir]
          @tmp_dir            = @opts[:tmp_dir]
        end

        # Takes list of paths/globs and returns Array of existing files
        # - Non-existent paths will be discarded with a warning message
        # @param str [String] list of paths/path globs, delimited by `:` or `,`
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

        # Return path to
        def run(label = nil)
          label ||= (ENV['MATRIX_LABEL'] || 'build') + Time.now.utc.strftime('_%Y%m%d_%H%M%S')
          iteration_total = @iterations.size
          iteration_number = 0
          Dir.chdir(@opts[:base_dir]) do |_dir|
            @iterations.each do |cfg|
              iteration_number += 1
              simp_iso_json = cfg[:json]
              vars_data     = Simp::Packer::VarsJson.parse_file(simp_iso_json)

              os_name       = "#{vars_data['dist_os_flavor']}#{vars_data['dist_os_maj_version']}".downcase
              fips          = (cfg[:fips] || 'on') == 'on'
              encryption    = (cfg[:encryption] || 'off') == 'on'
              firmware      = (cfg[:firmware] || 'bios')
              simp_iso_file = iso_url_or_best_guess(vars_data, simp_iso_json)
              vars_data['iso_url'] = simp_iso_file

              iteration_dir  = "#{label}__#{vars_data['box_simp_release']}__#{os_name}_#{firmware}_#{fips ? 'fips' : 'nofips'}"
              iteration_dir += '_encryption' if encryption
              iteration_summary = "os=#{os_name} fips=#{fips ? 'on' : 'off'}"
              iteration_summary = ' encryption=on' if encryption
              vm_description =  "SIMP#{vars_data['box_simp_release']}-#{os_name.upcase}-#{firmware.upcase}-#{fips ? 'FIPS' : 'NOFIPS'}"
              log = "#{iteration_dir}.log"

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

              simp_conf_yaml = File.read(File.join(@packer_configs_dir, os_name, 'simp_conf.yaml'))
              packer_yaml = generate_packer_yaml(vm_description, os_name, fips, encryption, firmware)
              paths = scaffold_iteration_dir(iteration_dir, vars_data, packer_yaml, simp_conf_yaml)

              sh "date > '#{log}'"
              #
              #  remove me
              #
              packer_build_runner = Simp::Packer::Build::Runner.new(File.expand_path(iteration_dir))

              File.open(log, 'a') { |f| f.puts iterator_header_msg }
              packer_build_runner.run(
                log_file: log,
                tmp_dir: @tmp_dir,
                extra_packer_args: @opts[:extra_packer_args] || '--on-error=ask',
              )
              next if @opts[:dry_run]

              new_box = File.expand_path("#{iteration_dir}/OUTPUT/#{vm_description}.box")
              vagrant_box_name = [
                vars_data['box_simp_release'],
                cfg[:os],
                vars_data['dist_os_flavor'],
                vars_data['dist_os_version'],
                "x86_64", # TODO: add architecture to `rake build:auto`-genned vars.json
                "#{fips ? 'fips' : 'nofips').to_s}-#{firmware}#{encryption ? '-encryption' : ''}",
              ].join('-')

              Simp::Packer::Publish::LocalDirTree.publish(
                paths['vars.json'],
                new_box,
                @opts[:vagrant_box_dir],
                :hardlink,
                { org: 'simpci', name: "server-#{vagrant_box_name}", desc: "SIMP Server #{vagrant_box_name}" },
              )
              sh "date >> '#{log}'"
            end
          end
        end

        def generate_packer_yaml(vm_description, os_name, fips, encryption, firmware)
          packer_yaml_lines = File.read(File.join(@packer_configs_dir, os_name, 'packer.yaml')).split(%r{\n})
          packer_yaml_lines.delete_if { |x| x =~ %r{^(disk_encrypt|vm_description|firmware|fips|headless):} }
          packer_yaml_lines << "vm_description: '#{vm_description}'"
          packer_yaml_lines << "fips: 'fips=#{fips ? '1' : '0'}'"
          packer_yaml_lines << "headless: 'true'"
          packer_yaml_lines << "firmware: '#{firmware}'"

          if encryption
            packer_yaml_lines << "disk_encrypt: 'true'"
            packer_yaml_lines.select { |x| x =~ %r{^big_sleep} }.each { |x| x.sub!('<wait10>', '<wait10>' * 12) }
          else
            packer_yaml_lines << "disk_encrypt: 'false'"
          end
          packer_yaml_lines.join("\n")
        end

        # If the file doesn't exist at the JSON file's 'iso_url' key,
        # Try using the JSON file's name, except with the suffix '.iso'
        # @return [String] Path to SIMP ISO file
        def iso_url_or_best_guess(vars_data, simp_iso_json)
          same_patt = Dir[simp_iso_json.gsub(%r{\.json$}, '.iso')].first
          # TODO: support http URLs? (packer does)
          if File.file?(vars_data['iso_url'].gsub(%r{^file://}, ''))
            simp_iso_file = vars_data['iso_url'].gsub(%r{^file://}, '')
            warn "INFO: ISO found at iso_url in '#{simp_iso_json}':\n  Using ISO '#{simp_iso_file}'"
          elsif File.file?(same_patt)
            simp_iso_file = same_patt
            warn "INFO: falling back to ISO at same path/naming scheme as json file:\n  Using ISO '#{simp_iso_file}'"
          end
          simp_iso_file
        end

        # - create a new directory for the simp-packer "test"
        #   - copy the basic config files from a sample directory
        #   - tweak them to match this test parameter
        #   - modify the local vars.json to build from our SIMP ISO
        # @return [String] path to local vars.json file
        def scaffold_iteration_dir(dir, vars_data, packer_yaml, simp_conf_yaml)
          paths = {
            'vars.json'      => File.expand_path('vars.json', dir),
            'simp_conf.yaml' => File.expand_path('simp_conf.yaml', dir),
            'packer.yaml'    => File.expand_path('packer.yaml', dir)
          }
          mkdir_p dir
          File.open(paths['vars.json'], 'w') { |f| f.puts JSON.pretty_generate(vars_data) }
          File.open(paths['simp_conf.yaml'], 'w') { |f| f.puts simp_conf_yaml }
          File.open(paths['packer.yaml'], 'w') { |f| f.puts packer_yaml }
          paths
        end

        # Filter unrolled matrix down to iterations with valid SIMP ISO json
        #   files that match their os
        def iterations_with_valid_simp_json(unrolled_matrix)
          unique_json_files = unrolled_matrix.map { |c| c[:json] }.uniq
          data_by_file = data_from_json_files(unique_json_files)
          el_oses = ['RedHat', 'CentOS', 'OracleLinux', 'Scientific']
          unrolled_matrix.select do |i|
            data = data_by_file.dig(i[:json]) or next
            maj_ver = i[:os].sub(%r{^el}, '')
            is_el = el_oses.include?(data['dist_os_flavor'])
            (is_el && (maj_ver == data['dist_os_maj_version']))
          end
        end

        # @param json_files [Array<String>] Paths to JSON files
        # @return [Hash] Data from each valid JSON file
        def data_from_json_files(json_files)
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
      end
    end
  end
end
