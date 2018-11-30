module Simp
  module Tests
    module Puppet
      # Pass through environment variables that users/CI should be able to influence
      def filtered_env_vars
        (
          ENV.to_h.select do |k, _v|
            k =~ %r{^SIMP_|^BEAKER_|^PUPPET_|^FACTER_|^DEBUG|^VERBOSE|^FLAGS$}
          end
        )
      end

      def run_rake_tasks(cmds)
        Bundler.with_clean_env do
          cmds.each do |cmd|
            line = cmd.to_s
            puts "\n\n==== EXECUTING: #{line}\n"
            exit 1 unless system(filtered_env_vars, line)
          end
        end
      end

      # Try fetching from local resources before using remote resources
      def careful_bundle_install_cmd
        bundle = 'bundle install --no-binstubs'
        %[bundle check || rm -f Gemfile.lock \
          && (#{bundle} --local || #{bundle} || bundle pristine || #{bundle}) \
          || { echo "bundler couldn't find everything"; exit 88 ; }]
      end

      def run_puppet_rake_tests
        run_rake_tasks [
          careful_bundle_install_cmd,
          'bundle exec rake validate',
          'bundle exec rake lint',
          'bundle exec rake metadata_lint',
          'bundle exec rake test'
        ]
      end
    end
  end
end
