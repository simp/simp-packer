require 'rake/file_utils'

module Simp
  module Packer
    module Tests
      class Shellcheck
        include FileUtils

        def initialize(shellcheck_bin)
          @shellcheck_bin = shellcheck_bin
        end

        def no_shellcheck_message
          <<NO_SHELLCHECK_MESSAGE

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
        end

        def fail_no_shellcheck
          warn no_shellcheck_message
          exit 81
        end

        def run
          begin
            system %(which #{@shellcheck_bin} &> /dev/null || exit 81)
            # This line can help troubleshoot differences of `shellcheck`
            # versions between local development environments and CI:
            sh %(#{@shellcheck_bin} --version || exit 81)
            sh %(shellcheck --exclude=2039 *.sh scripts/*.sh scripts/**/*.sh)
          rescue RuntimeError => e
            fail_no_shellcheck if e.to_s =~ %r{\b81\b}
            warn '-' * 80
            raise e
          end
          puts '-' * 80, "``#{@shellcheck_bin}\` checks passed.  Hooray!", '-' * 80
        end
      end
    end
  end
end

