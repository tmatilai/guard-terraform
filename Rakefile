# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: %w[test style]

desc 'Run all tests'
task test: ['test:unit']

namespace :test do
  desc 'Run unit tests'
  RSpec::Core::RakeTask.new(:unit) do |task|
    task.pattern = 'spec/**/*_spec.rb'
  end
end

desc 'Run all style checks'
task style: ['style:ruby']

namespace :style do
  desc 'Run style checks for Ruby'
  RuboCop::RakeTask.new(:ruby)
end
