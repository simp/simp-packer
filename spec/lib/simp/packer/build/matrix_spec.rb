# frozen_string_literal: true

require 'simp/packer/build/matrix'
require 'simp/packer/publish/local_dir_tree'
require 'support/vars_json_helpers'
require 'spec_helper'
require 'tmpdir'
require 'tempfile'
require 'digest/sha2'

RSpec.configure do |c|
  c.include VarsJsonHelpers
end

# rubocop:disable RSpec/InstanceVariable, RSpec/BeforeAfterAll, RSpec/MultipleMemoizedHelpers
describe Simp::Packer::Build::Matrix do
  before(:all) { @tmpdir = Dir.mktmpdir('spec_simp-packer-build-matrix') }

  after(:all) { FileUtils.rm_rf @tmpdir }

  let(:iso_release_types) { ['el7', 'el8'] }
  let(:iso_json_files) do
    iso_files.map { |rel, _iso_file|
      json_file = File.join(@tmpdir, "fake-simp-iso-#{rel}.json")
      [rel, json_file]
    }.to_h
  end
  let(:iso_json_file_glob) { File.join(@tmpdir, 'fake-simp-iso-el?.json*') }
  let(:matrix_opts) do
    {
      'fips' => ['on', 'off'],
      'os'   => ['el7', 'el8']
    }
  end
  let(:matrix_args) do
    matrix_opts.map { |k, v| "#{k}=#{v.join(':')}" }
  end
  let(:iso_files) do
    iso_files = {}
    iso_release_types.each do |rel|
      iso = Tempfile.new("fake-#{rel}-iso-", @tmpdir)
      iso.write("Fake #{rel} ISO")
      iso_files[rel] = iso
    end
    iso_files
  end

  before(:each) do
    iso_files.map do |rel, iso_file|
      json_file = File.join(@tmpdir, "fake-simp-iso-#{rel}.json")
      File.open(json_file, 'w') do |f|
        f.puts(JSON.pretty_generate(mock_vars_json_data(
                                      os_maj_rel: rel.match(%r{\d+}).to_a.first,
                                      iso_file_path: iso_file.path,
                                    )))
      end
    end
  end

  context 'with os=el7:el8,fips=on:off' do
    subject(:nsubject) { described_class.new(matrix_args, constructor_opts) }

    let(:matrix_opts) do
      {
        'fips' => ['on', 'off'],
        'os'   => ['el7', 'el8']
      }
    end

    let(:expected_matrix) do
      combinations = matrix_opts.reduce([{}]) do |matrix_hashes, kv|
        v_hashes = kv.last.reduce([]) { |hashes, v| hashes << { kv.first.to_sym => v } }
        matrix_hashes.map { |m_hash| v_hashes.map { |v_hash| m_hash.merge(v_hash) } }.flatten(1)
      end
      combinations.map { |h| { json: iso_json_files[h[:os]] }.merge(h) }
    end

    context 'with vars.json glob via constructor opts' do
      let(:constructor_opts) do
        {
          simp_iso_json_files: iso_json_file_glob,
          base_dir: @tmpdir
        }
      end

      describe '#initialize' do
        it 'intializes with correct matrix' do
          expect(nsubject.instance_variable_get('@iterations')).to match_array expected_matrix
        end
      end

      describe '#run' do
        it 'iterates the correct number of times' do
          n = expected_matrix.size
          runner_double = instance_double('Simp::Packer::Build::Runner')

          expect(Simp::Packer::Build::Runner).to receive(:new).exactly(n).times.and_return(runner_double)
          expect(runner_double).to receive(:run).exactly(n).times
          expect(Simp::Packer::Publish::LocalDirTree).to receive(:publish).exactly(n).times
          nsubject.run
        end
      end
    end

    context 'with vars.json list via json= matrix args' do
      let(:constructor_opts) { {} }
      let(:matrix_args) { super() << "json=#{iso_json_files.values.join(':')}" }

      describe '#initialize' do
        it 'intializes with correct matrix' do
          expect(nsubject.instance_variable_get('@iterations')).to match_array expected_matrix
        end
      end
    end
  end
end
# rubocop:enable RSpec/InstanceVariable, RSpec/BeforeAfterAll, RSpec/MultipleMemoizedHelpers
