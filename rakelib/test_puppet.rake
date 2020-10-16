# frozen_string_literal: true

require 'simp/tests/puppet'

namespace :test do
  desc 'Test Puppet modules'
  task :puppet do
    include Simp::Tests::Puppet
    Dir[File.join('puppet', 'modules', '*')].each do |dir|
      Dir.chdir dir do
        run_puppet_rake_tests
      end
    end
  end
end
