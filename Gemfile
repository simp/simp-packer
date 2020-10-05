# ------------------------------------------------------------------------------
# NOTE: SIMP Puppet rake tasks support ruby 2.1.9
# ------------------------------------------------------------------------------
gem_sources = ENV.fetch('GEM_SERVERS','https://rubygems.org').split(/[, ]+/)

gem_sources.each { |gem_source| source gem_source }

group :test do
  puppet_version = ENV['PUPPET_VERSION'] || '~> 5.5'
  major_puppet_version = puppet_version.scan(/(\d+)(?:\.|\Z)/).flatten.first.to_i
  gem 'rake'
  gem 'puppet', puppet_version
  gem 'rspec'
  gem 'rspec-mocks'
  gem 'rspec-puppet'
  gem 'hiera-puppet-helper'
  gem 'puppetlabs_spec_helper'
  gem 'metadata-json-lint'
  gem 'puppet-strings'
  gem 'puppet-lint-empty_string-check',   :require => false
  gem 'puppet-lint-trailing_comma-check', :require => false
  gem 'simp-rspec-puppet-facts', ENV.fetch('SIMP_RSPEC_PUPPET_FACTS_VERSION', '~> 3.1')
  gem 'simp-rake-helpers', ENV.fetch('SIMP_RAKE_HELPERS_VERSION', '~> 5.11')
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'yard'
  gem 'redcarpet'
  gem 'github-markup'
  gem 'simplecov', require: false
  gem('pdk', ENV['PDK_VERSION'] || '~> 1.0', :require => false) if major_puppet_version > 5
end

group :development do
  gem 'travis'
  gem 'travish'
  gem 'pry'
  gem 'pry-doc'
end

group :system_tests do
  gem 'beaker'
  gem 'beaker-rspec'
  gem 'simp-beaker-helpers', ENV.fetch('SIMP_BEAKER_HELPERS_VERSION', '~> 1.14')
end
