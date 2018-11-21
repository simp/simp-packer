require 'simp/packer/build/runner'
require 'spec_helper'
require 'tmpdir'

describe Simp::Packer::Build::Runner do
  before(:all) do
    @dir = Dir.mktmpdir('spec_simp-packer-runner')
    @obj = described_class.new @dir
    @obj.verbose = false
  end

  after(:all) do
    FileUtils.rm_rf @dir
  end

  describe '#prep' do
    before :all do
      @obj.prep(
        'spec/lib/simp/packer/build/files/vars_json/v0/SIMP-6.2.0-0.el7-CentOS-7.0-x86_64.json',
        'spec/lib/simp/packer/build/files/runner/basic/simp_conf.yaml',
        'spec/lib/simp/packer/build/files/runner/basic/packer.yaml'
      )
    end

    it 'places simp_conf.yaml in the test directory' do
      expect(File).to exist("#{@dir}/simp_conf.yaml")
    end

    it 'places packer.yaml in the test directory' do
      expect(File).to exist("#{@dir}/packer.yaml")
    end

    it 'places vars.json in the test directory' do
      expect(File).to exist("#{@dir}/vars.json")
    end
  end

  describe '#run' do
    before :all do
      @obj.run(dry_run: true)
    end

    it 'fails if the test_dir does not exist' do
      obj = described_class.new '/dev/null/foo'
      expect { obj.run }.to raise_error(RuntimeError, %r{ERROR: Test dir not found at '/dev/null/foo'})
    end

    it 'creates a working directory' do
      expect(Dir["#{@dir}/working.*"].size).to be > 0
    end

    it 'populates the working directory' do
      expect(Dir["#{@dir}/working.*/*"].map { |x| File.basename(x) }).to include(
        'files', 'puppet', 'scripts', 'simp.json', 'vars.json'
      )
    end
  end
end
