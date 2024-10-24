# frozen_string_literal: true

require_relative 'lib/icinga2/api/version'

Gem::Specification.new do |s|
  s.name        = 'icinga2-api-client'
  s.version     = Icinga2::API::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Nicolas Rodriguez']
  s.email       = ['nico@nicoladmin.fr']
  s.homepage    = 'https://github.com/jbox-web/icinga2-api-client'
  s.summary     = 'Interface to interact with the Icinga2 API'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.1.0'

  s.files = Dir['README.md', 'LICENSE', 'lib/**/*.rb']

  s.add_dependency 'activesupport', '>= 7.0'
  s.add_dependency 'faraday'
  s.add_dependency 'zeitwerk', '~> 2.6.0'
end
