# frozen_string_literal: true

require 'simp/packer/vars_json_to_vagrant_box_json'
require 'spec_helper'
require 'support/vars_json_helpers'
require 'tempfile'
require 'json'

RSpec.configure do |c|
  c.include VarsJsonHelpers
end

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll
describe Simp::Packer::VarsJsonToVagrantBoxJson do
  before(:all) { @tmpdir = Dir.mktmpdir('spec_simp-packer-vars-json') }

  after(:all) { FileUtils.rm_rf @tmpdir }

  let(:fake_iso_path) do
    file = Tempfile.new('vars.json--fake.iso', @tmpdir)
    file.write('test iso file')
    file.flush
    file.path
  end

  let(:mocked_iso_data) do
    {
      'box_simp_release'    => '6.6.0-0',
      'dist_os_flavor'      => 'CentOS',
      'dist_os_maj_version' => '7',
      'dist_os_version'     => '7.8'
    }
  end

  let(:vars_json_path) do
    file = Tempfile.new('vars.json', @tmpdir)
    file.write(JSON.pretty_generate(mock_vars_json_data(
                                      os_maj_rel: '7',
                                      iso_file_path: fake_iso_path,
                                      data: mocked_iso_data,
                                    )))
    file.flush
    file.path
  end

  context 'with default options' do
    subject(:obj) do
      described_class.new(vars_json_path, {})
    end

    describe '#initialize' do
      it 'intializes without problems' do
        expect { obj }.not_to raise_error
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll
