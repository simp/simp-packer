desc 'Run all testing tasks'
task :test => [
  'test:shellcheck',
  'test:rubocop',
  'test:puppet'
]
