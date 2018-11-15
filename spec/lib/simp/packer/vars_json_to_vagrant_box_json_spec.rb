require 'simp/packer/vars_json_to_vagrant_box_json'
require 'spec_helper'

describe Simp::Packer::VarsJsonToVagrantBoxJson do
  before(:all) do
    @obj = described_class.new(
      'spec/lib/simp/packer/files/vars_json/v0/SIMP-6.2.0-0.el7-CentOS-7.0-x86_64.json',
      {}
    )
  end

  it 'does what it is supposed to do', :skip => 'TODO: implement this test' do
    expect(@rendered_content).to eq @expected_content
  end
end
