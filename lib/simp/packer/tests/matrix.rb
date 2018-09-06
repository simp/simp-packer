require 'simp/packer/tests/matrix_unroller'
module Simp
  module Packer
    module Tests
      class Matrix
        include MatrixUnroller
        # @param matrix [Array] matrix of things
        def initialize(matrix)
          @iterations = unroll matrix

          @iso_dir = ENV['ISO_DIR'] || '/opt/ctessmer/ISO'
          @src_dir = ENV['SRC_DIR'] || '/opt/ctessmer/src'
          @box_dir = ENV['BOX_DIR'] || '/opt/ctessmer/vagrant'

          @dir_name           = ENV['DIR_NAME']           || "test"
          @simp_iso_dir       = ENV['SIMP_ISO_DIR']       || "${ISO_DIR}/SIMP-6.2.0-RC1"
          @simp_iso_file      = ENV['SIMP_ISO_FILE']      || "SIMP-6.2.0-RC1.el7-CentOS-7.0-x86_64.iso"
          @simp_iso_json      = ENV['SIMP_ISO_JSON']      || "SIMP-6.2.0-RC1.el7-CentOS-7.0-x86_64.json"
          @simp_packer_dir    = ENV['SIMP_PACKER_DIR']    || "${SRC_DIR}/simp-packer"
          @simp_packer_sample = ENV['SIMP_PACKER_SAMPLE'] || "fips7"
          @centos_7_dvd_file  = ENV['CENTOS_7_DVD_FILE']  || "CentOS-7-x86_64-DVD-1708.iso"
          @centos_6_dvd_file  = ENV['CENTOS_6_DVD_FILE']  || "CentOS-6.9-x86_64-bin-DVD1.iso"
        end

        def run(label = 'test_' + Time.now.utc.strftime('%Y%m%d.%H%M%S'))
          @iterations.each do |cfg|
            el         = "el#{cfg[:el] || '7'}"
            fips       = (cfg[:fips] || 'on') == 'on'
            encryption = (cfg[:encryption] || 'off') == 'on'
            iteration  = "#{label}_#{el}_#{fips ? 'fips' : 'nofips'}"
            iteration += '_encryption' if encryption
            puts el, fips, encryption
            src_dir = 'fips7' if el == 'el7'
            puts "==== matrix iteration: #{cfg} (src_dir: #{src_dir})"
          end
        end
      end
    end
  end
end
