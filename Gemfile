# frozen_string_literal: true

source 'https://rubygems.org'

# Specify the gem's dependencies in guard-terraform.gemspec
gemspec

gem 'bundler', '~> 2.0'
gem 'rake', '~> 12.0'
gem 'rspec', '~> 3.0'

# Locked down due to a bug in 0.63.0:
# https://github.com/rubocop-hq/rubocop/issues/6677
gem 'rubocop', '= 0.62'

group :development do
  gem 'guard-rspec', '~> 4.7'
  gem 'guard-rubocop', '~> 1.3'
end
