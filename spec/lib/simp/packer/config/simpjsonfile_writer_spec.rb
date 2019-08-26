require 'simp/packer/config/simpjsonfile_writer'
require 'pry'
require 'pry-byebug'
require 'spec_helper'


describe Simp::Packer::Config::SimpjsonfileWriter do
  describe '#render' do
    let(:settings) {[
       {
         "firmware"     => "bios",
         "disk_encrypt" => "false",
         "fips"         => "fips=0",
         "bootcmd"      => 'simp'
       },
       {
         "firmware"     => "bios",
         "disk_encrypt" => "true",
         "fips"         => "fips=1",
         "bootcmd"       => 'simp'
       },
       {
         "firmware"     => "bios",
         "disk_encrypt" => "false",
         "fips"         => "fips=1",
         "bootcmd"      => 'simp'
       },
       {
         "firmware"     => "bios",
         "disk_encrypt" => "true",
         "fips"         => "fips=0",
         "bootcmd"       => 'simp'
       },
    ]}

    let(:basedir) {
       File.expand_path('../../../../../../',__FILE__)
    }

    it "returns expected content " do
      s = {"bootcmd" => 'simp' }
      ['6','7'].each do | os_ver |
        s['os_ver'] = os_ver
        ['bios','efi'].each  do | firmware |
          s['firmware'] = firmware
          ['false', 'true'].each do | disk_encrypt |
            s['disk_encrypt'] = disk_encrypt
            ['fips=0','fips=1'].each do | fips |
              s['fips'] = fips

              puts "settings #{s}"
              myclass = described_class.new(s, basedir)
              rendered_content = myclass.render "simp.json/bootcmd/#{s['firmware']}.erb"
              expected_content = File.read("spec/lib/simp/packer/config/files/simp.json/examples.#{s['os_ver']}.#{s['firmware']}.#{s['disk_encrypt']}.#{s['fips']}.txt")
              expect(rendered_content).to eq expected_content
            end
          end
        end
      end
    end
  end
end
