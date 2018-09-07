require 'simp/packer/tests/matrix_unroller'
require 'fileutils'
module Simp
  module Packer
    module Tests
      class Matrix
        include MatrixUnroller
        include FileUtils
        # @param matrix [Array] matrix of things
        def initialize(matrix)
          @iterations = unroll matrix

          @iso_dir = ENV['ISO_DIR'] || '/opt/ctessmer/ISO'
          @src_dir = ENV['SRC_DIR'] || '/opt/ctessmer/src'
          @box_dir = ENV['BOX_DIR'] || '/opt/ctessmer/vagrant'

          @dir_name           = ENV['DIR_NAME']           || 'test'
          @simp_iso_dir       = ENV['SIMP_ISO_DIR']       || File.join(@iso_dir, 'simp', 'prereleases')
          @simp_iso_file      = ENV['SIMP_ISO_FILE']      || \
                                File.join(@simp_iso_dir, 'SIMP-6.2.0-RC1.%OS%-CentOS-?.?-x86_64.iso')
          @simp_iso_json      = ENV['SIMP_ISO_JSON']      || @simp_iso_file.sub(%r{\.iso$}, '.json')
          @simp_packer_dir    = ENV['SIMP_PACKER_DIR']    || File.join(@src_dir, 'simp-packer')
          @simp_packer_sample = ENV['SIMP_PACKER_SAMPLE'] || 'fips7'
          @centos_7_dvd_file  = ENV['CENTOS_7_DVD_FILE']  || 'CentOS-7-x86_64-DVD-1708.iso'
          @centos_6_dvd_file  = ENV['CENTOS_6_DVD_FILE']  || 'CentOS-6.9-x86_64-bin-DVD1.iso'
        end

        def run(label = 'test_' + Time.now.utc.strftime('%Y%m%d.%H%M%S'))
          @iterations.each do |cfg|
            os         = cfg[:os]
            fips       = (cfg[:fips] || 'on') == 'on'
            encryption = (cfg[:encryption] || 'off') == 'on'
            iteration  = "#{label}_#{os}_#{fips ? 'fips' : 'nofips'}"
            iteration += '_encryption' if encryption
            sample_dir = 'fips7' if os == 'el7'
            sample_dir = 'fips6' if os == 'el6'

            simp_iso_file = Dir[@simp_iso_file.gsub('%OS%', os)].first
            simp_iso_json = Dir[@simp_iso_json.gsub('%OS%', os)].first
            puts "\n==== Matrix iteration: #{cfg} '#{iteration}"
            puts "SIMP_PACKER_SAMPLE:    #{sample_dir}"
            puts "DIR_NAME:              #{@dir_name}"
            puts "SIMP_ISO_DIR:          #{@simp_iso_dir}"
            puts "SIMP_ISO_FILE:         #{simp_iso_file}"
            puts "SIMP_ISO_JSON:         #{simp_iso_json}"
            puts "SIMP_PACKER_DIR:       #{@simp_packer_dir}"
            puts "SIMP_PACKER_SAMPLE:    #{@simp_packer_sample}"

            raise "ERROR: no .iso file at #{simp_iso_file}" unless File.exist?(simp_iso_file)
            raise "ERROR: no .json file at #{simp_iso_json}" unless File.exist?(simp_iso_json)
            # create a new simp-packer "sample" directory
            # copy the basic assets from the model sample
            # tweak it to taste based on our settings
            mkdir_p @dir_name
            Dir.chdir(@dir_name) do |dir|
              cp File.join(@simp_packer_dir, 'samples', @simp_packer_sample, 'simp_conf.yaml'), dir
              cp File.join(@simp_packer_dir, 'samples', @simp_packer_sample, 'simp_packer.yaml'), dir
              cp simp_iso_json, File.join(dir, 'vars.json')

              # translate the actual ISO file in
            end
          end
        end
      end
    end
  end
end
