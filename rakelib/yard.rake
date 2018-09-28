require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files = ['*.rb', 'rakelib/*.rake', 'scripts/**/*.rb', 'lib/**/*.rb']
end
