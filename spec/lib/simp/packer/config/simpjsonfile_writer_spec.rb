require 'simp/packer/config/simpjsonfile_writer'
require 'pry'
require 'pry-byebug'
require 'spec_helper'


describe Simp::Packer::Config::SimpjsonfileWriter do
  describe '#render' do
    let(:settings) {[
       {
         "firmware" => "bios",
         "disk_encrypt" => "false",
         "fips"         => "fips=0",
         "bootcmd-prefix" => 'simp'
       },
       {
         "firmware" => "bios",
         "disk_encrypt" => "true",
         "fips"         => "fips=1",
         "bootcmd-prefix" => 'simp'
       },
       {
         "firmware" => "efi",
         "disk_encrypt" => "false",
         "fips"         => "fips=1",
         "bootcmd-prefix" => 'simp'
       },
       {
         "firmware" => "bios",
         "disk_encrypt" => "true",
         "fips"         => "fips=0",
         "bootcmd-prefix" => 'simp'
       },
    ]}

    let(:basedir) {
       File.expand_path('../../../../../../',__FILE__)
    }

    it "returns expected content" do
      settings.each  do | s |
         myclass = described_class.new(s, basedir)
         rendered_content = myclass.render "simp.json/bootcmd/#{s['firmware']}.erb"
#        rendered_content = described_class.new(s, basedir).render 'simp.json.erb'
        expected_content = File.read("spec/lib/simp/packer/config/files/simp.json/examples.#{s['firmware']}.#{s['disk_encrypt']}.#{s['fips']}.txt")
        expect(rendered_content).to eq expected_content
      end
    end
  end
end
