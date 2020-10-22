# frozen_string_literal: true

namespace :simp do
  namespace :packer do
    desc <<-DESC.gsub(%r{^    }, '')
      Creates a packer build from a test directory that contains a packer.yaml
      simp_config.yaml and vars.json file. This is like the old builds.
      This just makes life easier for Jeanne right now, and that is very important.

     * test_dir        (Required) Path to test directory
                        ENV: SIMP_PACKER_test_dir)
    DESC
    task :oldbuild, [:test_dir] do |t, args|
      require 'simp/packer/build/runner'
      unless ENV['SIMP_PACKER_test_dir']
        msg = ['ERROR:  You must supply the test directory ']
        msg << "\nrake #{t.name_with_args}\n"
        msg += t.full_comment.split("\n").map { |x| "    #{x}" }
        msg << "\n"

        raise  msg.join("\n") unless args.test_dir

        args.with_defaults(test_dir: ENV['SIMP_PACKER_test_dir'])
      end
      packer_build_runner = Simp::Packer::Build::Runner.new(args.test_dir)
      packer_build_runner.run
    end
  end
end
