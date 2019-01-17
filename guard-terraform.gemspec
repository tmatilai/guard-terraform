# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guard/terraform/version'

Gem::Specification.new do |spec|
  spec.name        = 'guard-terraform'
  spec.version     = Guard::TerraformVersion::VERSION
  spec.summary     = 'Guard plugin for Terraform configuration format'
  spec.description = 'Guard plugin for checking and optionally fixing ' \
                     'Terraform configuration formatting and style.'
  spec.homepage    = 'https://github.com/tmatilai/guard-terraform'
  spec.license     = 'MIT'

  spec.authors = [
    'Teemu Matilainen',
  ]
  spec.email = [
    'teemu.matilainen@iki.fi',
  ]

  spec.metadata = {
    'homepage_uri'      => spec.homepage,
    'source_code_uri'   => spec.homepage,
    'documentation_uri' => "#{spec.homepage}#readme",
    'changelog_uri'     => "#{spec.homepage}/blob/master/CHANGELOG.md",
    'bug_tracker_uri'   => "#{spec.homepage}/issues"
  }

  spec.files = Dir['lib/**/*.rb'] +
               Dir['lib/**/Guardfile']

  spec.require_paths = ['lib']

  spec.add_dependency 'guard', '~> 2.0'
end
