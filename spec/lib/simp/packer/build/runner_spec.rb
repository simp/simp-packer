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

  shared_examples_for 'a successful run' do
    it 'fails if the test_dir does not exist' do
      obj = described_class.new '/dev/null/foo'
      expect { obj.run }.to raise_error(RuntimeError, %r{ERROR: Test dir not found at '/dev/null/foo'})
    end

    it 'creates a working directory' do
      @obj.run(dry_run: true)
      expect(Dir["#{@dir}/working.*"].size).to be > 0
    end

    it 'populates the working directory' do
      @obj.run(dry_run: true)
      expect(Dir["#{@dir}/working.*/*"].map { |x| File.basename(x) }).to include(
        'files', 'puppet', 'scripts', 'simp.json', 'vars.json'
      )
    end
  end

  describe '#run' do
    before :all do
      @hostonlyifs = File.read('spec/lib/simp/packer/config/files/vboxmanage-list-hostonlyifs.txt')
    end

    before do
      allow_any_instance_of(Kernel).to receive(:`).with('VBoxManage list hostonlyifs').and_return @hostonlyifs
    end

    context 'with an existing hostonly network' do
      it_behaves_like 'a successful run'
    end

    context 'without an existing hostonly network' do
      before do
        allow_any_instance_of(Kernel).to receive(:`).with(
          'VBoxManage list hostonlyifs'
        ).and_return('')

        allow_any_instance_of(Kernel).to receive(:`).with(
          'VBoxManage hostonlyif create'
        ).and_return("Interface 'vboxnet5' was successfully created")
      end

      context 'when able to configure the network' do
        before do
          allow_any_instance_of(Kernel).to receive(:system).with(
            'VBoxManage hostonlyif ipconfig vboxnet5 --ip 192.168.101.1 --netmask 255.255.255.0'
          ).and_return(true)
        end

        it_behaves_like 'a successful run'
      end

      context 'when unable to configure the network' do
        before do
          allow_any_instance_of(Kernel).to receive(:system).with(
            'VBoxManage hostonlyif ipconfig vboxnet5 --ip 192.168.101.1 --netmask 255.255.255.0'
          ).and_return(false)
        end

        it 'fails with an error' do
          expect { @obj.run(dry_run: true) }.to raise_error(RuntimeError,
                                                            %r{Failure to configure.*VBoxManage hostonlyif ipconfig vboxnet5})
        end
      end
    end
  end
end
