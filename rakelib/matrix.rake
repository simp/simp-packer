# frozen_string_literal: true

require 'simp/packer/build/matrix'
require 'rake'

namespace :simp do
  namespace :packer do
    def matrix_fail_msg(task)
      <<~FAIL

      --------------------------------------------------------------------------------
      ERROR: Task arguments must provide a matrix string
      --------------------------------------------------------------------------------

      Usage:

        rake #{task.name_with_args}[MATRIX]

      #{task.full_comment.sub(%r{^#{task.comment}}, '').strip}

      --------------------------------------------------------------------------------

      FAIL
    end

    desc <<~DESC
      Run simp_packer_test.sh in a matrix of various conditions

      Examples:

        rake simp:packer:matrix[os=el6:el7]
        rake simp:packer:matrix[os=el6:el7,fips=on:off]

    DESC
    task :matrix => [:clean] do |task, args|
      if args.extras.empty?
        t = task.application.tasks.select { |x| x.name == task.name }.first
        raise ArgumentError, matrix_fail_msg(t)
      end

      Simp::Packer::Build::Matrix.new(args.extras).run
    end
  end
end
