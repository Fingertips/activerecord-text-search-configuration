# frozen_string_literal: true

require File.expand_path('lib/active_record/text_search_configuration/version', __dir__)

Gem::Specification.new do |spec|
  spec.name = 'activerecord-text-search-configuration'
  spec.version = ActiveRecord::TextSearchConfiguration::VERSION
  spec.authors = [
    'Manfred Stienstra'
  ]
  spec.email = [
    'manfred@fngtps.com'
  ]
  spec.summary = <<-SUMMARY
  Text search configuration support for Active Record.
  SUMMARY
  spec.description = <<-DESCRIPTION
  Adds methods like create_text_search_configuration to manage search configurations in your
  Ruby on Rails project.
  DESCRIPTION
  spec.homepage = 'https://github.com/Fingertips/activerecord-text-search-configuration'
  spec.license = 'MIT'

  spec.files = Dir.glob('lib/**/*') + [
    'LICENSE',
    'README.md'
  ]
  spec.require_paths = ['lib']

  spec.required_ruby_version = '> 3.3'

  spec.add_dependency 'activerecord'

  spec.metadata = { 'rubygems_mfa_required' => 'true' }
end
