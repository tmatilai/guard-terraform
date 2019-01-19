# frozen_string_literal: true

group :ruby, halt_on_fail: true do
  guard :rspec, cmd: 'bundle exec rspec --format progress' do
    # RSpec files
    watch(%r{^spec/.+_spec\.rb$})
    watch('spec/spec_helper.rb') { 'spec' }
    watch(%r{^spec/support/.+\.rb$}) { 'spec' }
    watch(%r{^spec/fixtures/}) { 'spec' }

    # Ruby files
    watch(%r{^(lib/.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  end

  guard :rubocop do
    watch(/\.rb$/)
    watch(/\.gemspec$/)
    watch('Gemfile')
    watch('Rakefile')
    watch(%r{/Guardfile$})
    watch(/\.rubocop\.yml$/) { |m| File.dirname(m[0]) }
  end
end
