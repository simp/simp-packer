module Simp
  module Packer
    module TestMethods
      # Filter shell environment variables
      def filtered_env_vars_string
        filtered_env_vars = (
          ENV.to_h
           .select do |k, v|
            k =~ /^SIMP_|^BEAKER_|^PUPPET_|^FACTER_|NO_SELINUX_DEPS|^DEBUG|^VERBOSE|^FLAGS$/
          end
        )
        filtered_env_vars.map { |k, v| "#{k}=#{v}" }.join(' ')
      end

      # Run puppet testing rake tasks
      def run_rake_tasks(cmds)
        Bundler.with_clean_env do
          cmds.each do |cmd|
            line = "#{filtered_env_vars_string} #{cmd}"
            puts '', "==== EXECUTING: #{line}"
            exit 1 unless system(line)
          end
        end
      end
      def careful_bundle_cmds
        bundle = 'bundle install --no-binstubs --jobs $(nproc) "${FLAGS[@]}"'
        %[bundle check || rm -f Gemfile.lock \
          && (#{bundle} --local || #{bundle} || bundle pristine || #{bundle}) \
          || { echo "bundler couldn't find everything"; exit 88 ; }]
      end

      def run_puppet_rake_tests
        run_rake_tasks [
          careful_bundle_cmds,
          'bundle exec rake validate',
          'bundle exec rake lint',
          'bundle exec rake metadata_lint',
          'bundle exec rake test',
        ]
      end

      def run_puppet_rake_tests
        bundle = 'bundle install --no-binstubs --jobs $(nproc) "${FLAGS[@]}"'
        run_rake_tasks [
          %[bundle check || rm -f Gemfile.lock \
            && (#{bundle} --local || #{bundle} || bundle pristine || #{bundle}) \
            || { echo "bundler couldn't find everything"; exit 88 ; }],
          'bundle exec rake validate',
          'bundle exec rake lint',
          'bundle exec rake metadata_lint',
          'bundle exec rake test',
        ]
      end
    end
  end
end

namespace :puppet do
  desc "Test Puppet modules"
  task :test do
    include Simp::Packer::TestMethods
    Dir[File.join('puppet', 'modules', '*')].each do |dir|
      Dir.chdir dir do
        run_puppet_rake_tests
      end
    end
  end
end
