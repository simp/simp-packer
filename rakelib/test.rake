desc 'Run all testing tasks'
task :test => [
  'clean',
  'test:shellcheck',
  'test:rubocop',
  'test:puppet',
  'clean'
]
