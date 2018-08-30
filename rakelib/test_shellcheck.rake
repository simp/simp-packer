require 'simp/packer/tests/shellcheck'

namespace :test do
  desc 'List shell scripts (requires `shellcheck` executable in path)'
  task :shellcheck do
    shellcheck_bin = 'shellcheck'
    Simp::Packer::Tests::Shellcheck.new(shellcheck_bin).run
  end
end
