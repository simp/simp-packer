require 'simp/packer/tests/matrix'
require 'rake'
namespace :simp do
  namespace :packer do
    desc <<-BOXNAME_DESCRIPTION.gsub(%r{^ {6}}, '')
      Run simp_packer_test.sh in a matrix of various conditions

      Examples:

        rake simp:packer:matrix[os=el6:el7]
        rake simp:packer:matrix[os=el6:el7,fips=on:off]

    BOXNAME_DESCRIPTION
    task :matrix do |task, args|
      unless args.extras
        t = task.application.tasks.select { |x| x.name == task.name }.first
        raise ArgumentError, <<FAIL

--------------------------------------------------------------------------------
ERROR: must provide a matrix in task arguments:
--------------------------------------------------------------------------------

rake #{t.name_with_args}[MATRIX]
#{t.full_comment}

--------------------------------------------------------------------------------

FAIL
      end
      Simp::Packer::Tests::Matrix.new(args.extras).run
    end
  end
end
