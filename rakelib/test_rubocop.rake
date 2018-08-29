require 'rubocop/rake_task'

namespace :test do
  RuboCop::RakeTask.new(:rubocop) do |task, args|
    task.options = ['--config', '.rubocop.yml'] + args.to_a
  end
end
