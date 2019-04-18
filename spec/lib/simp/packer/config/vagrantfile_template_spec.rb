require 'simp/packer/config/vagrantfile_writer'
require 'spec_helper'

describe Simp::Packer::Config::VagrantfileWriter do
  describe '#render' do
    before(:all) do
      @rendered_content = described_class.new(
        'VM description text',
        '1.2.3.4',
        'aa:bb:cc:dd:ee:ff',
        'hostonly.tld',
        File.read('spec/lib/simp/packer/config/files/vagrantfile_templates/example.vagrantfile.erb.erb')
      ).render

      @expected_content = File.read('spec/lib/simp/packer/config/files/vagrantfile_templates/example.vagrantfile.erb.rendered')
    end

    it 'renders template as expected' do
      expect(@rendered_content).to eq @expected_content
    end
  end
end
