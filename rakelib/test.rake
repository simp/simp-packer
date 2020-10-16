# frozen_string_literal: true

desc 'Run all testing tasks'
task :test => [
  'clean',
  'test:shellcheck',
  'test:rubocop',
  'test:puppet',
  'clean',
]
