require 'simp/packer/build/matrix'
require 'rake'
namespace :simp do
  namespace :packer do
    desc <<-BOXNAME_DESCRIPTION.gsub(%r{^ {6}}, '')
      Run simp_packer_test.sh in a matrix of various conditions

      Examples:

        rake simp:packer:matrix[os=el6:el7]
        rake simp:packer:matrix[os=el6:el7,fips=on:off]

    BOXNAME_DESCRIPTION
    task :matrix => [:clean] do |task, args|
      if args.extras.empty?
        t = task.application.tasks.select { |x| x.name == task.name }.first
        raise ArgumentError, <<FAIL

--------------------------------------------------------------------------------
ERROR: Task arguments must provide a matrix string
--------------------------------------------------------------------------------

Usage:

  rake #{t.name_with_args}[MATRIX]

#{t.full_comment.sub(%r{^#{t.comment}}, '').strip}

--------------------------------------------------------------------------------

FAIL
      end
      Simp::Packer::Build::Matrix.new(args.extras).run
    end
  end
end
