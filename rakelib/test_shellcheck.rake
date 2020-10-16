# frozen_string_literal: true

require 'simp/tests/shellcheck'

namespace :test do
  desc 'List shell scripts (requires `shellcheck` executable in path)'
  task :shellcheck do
    shellcheck_bin = ENV['SHELLCHECK_BIN'] || 'shellcheck'
    Simp::Tests::Shellcheck.new(shellcheck_bin).run(['scripts/{*,**/*}.sh'])
  end
end
