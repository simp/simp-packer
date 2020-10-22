# frozen_string_literal: true

require 'rake/file_utils'

module Simp
  module Tests
    # A simple wrapper  class to run {https://www.shellcheck.net/ shellcheck}
    class Shellcheck
      include FileUtils

      # exit code when the shellcheck executable is not found
      NO_SHELLCHECK_EXIT_CODE = 81

      # shellcheck issues we generally don't care about
      #
      #  * SC2039: "In POSIX sh, ___ is not supported"
      #
      DEFAULT_SHELLCHECK_EXCLUDES = ['2039'].freeze

      # @param [String] shellcheck_bin  command/path to run shellcheck
      def initialize(shellcheck_bin = 'shellcheck')
        @shellcheck_bin = shellcheck_bin
      end

      # Run shellcheck on the given paths
      #
      # @param [Array<String>] paths  List of paths to check.
      #   paths can contain wildcards that will be expanded in the shell
      # @param [Array<String>] excludes List of numeric SC codes to exclude
      #   when running shellcheck
      #
      # @example Run shellcheck on specific paths
      #
      #    require 'simp/tests/shellcheck'
      #    sc = Simp::Tests::Shellcheck.new('shellcheck')
      #    sc.run(['scripts/*.sh', 'scripts/**/*.sh'])
      #
      def run(paths, excludes = DEFAULT_SHELLCHECK_EXCLUDES)
        begin
          system %(which #{@shellcheck_bin} &> /dev/null || exit 81)
          # This line can help troubleshoot differences of `shellcheck`
          # versions between local development environments and CI:
          sh %(#{@shellcheck_bin} --version || exit #{NO_SHELLCHECK_EXIT_CODE})
          sh %(shellcheck #{excludes.map { |x| "--exclude=#{x}" }.join(' ')} #{paths.join(' ')})
        rescue RuntimeError => e
          fail_no_shellcheck if e.to_s =~ %r{\b#{NO_SHELLCHECK_EXIT_CODE}\b}
        end
        puts '-' * 80, "`#{@shellcheck_bin}` checks passed.  Hooray!", '-' * 80
      end

      # Fail with a warning message
      def fail_no_shellcheck
        warn <<-NO_SHELLCHECK_MESSAGE.sub(%r{^ {10}}, '')

          --------------------------------------------------------------------------------
                             ERROR: \`#{@shellcheck_bin}\` NOT FOUND IN PATH
          --------------------------------------------------------------------------------

          This rake task requires the executable \`#{@shellcheck_bin}\`.

          The source is available at:

              https://github.com/koalaman/shellcheck

          On EL7 (using epel), the shellcheck 0.3.5 package can be installed with yum:

              yum install -y ShellCheck

          Newer versions can be compiled from source:

              https://github.com/koalaman/shellcheck#installing-the-shellcheck-binary

          --------------------------------------------------------------------------------

        NO_SHELLCHECK_MESSAGE
        exit NO_SHELLCHECK_EXIT_CODE
      end
    end
  end
end
