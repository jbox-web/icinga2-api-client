# frozen_string_literal: true

require_relative 'lib/icinga2/api/version'

Gem::Specification.new do |s|
  s.name        = 'icinga2-api-client'
  s.version     = Icinga2::API::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicolas Rodriguez']
  s.email       = ['nrodriguez@jbox-web.com']
  s.homepage    = 'https://github.com/jbox-web/active_use_case'
  s.summary     = 'Interface to interact with the Icinga2 API'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 2.6.0'

  s.files = `git ls-files`.split("\n")

  s.add_runtime_dependency 'activesupport', '>= 5.1'
  s.add_runtime_dependency 'rest-client'
  s.add_runtime_dependency 'zeitwerk'

  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'webmock'
end
