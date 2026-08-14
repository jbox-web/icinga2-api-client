# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# Dev libs
gem 'rake'
gem 'rspec'
gem 'simplecov'
gem 'vcr'
gem 'webmock'

# Dev tools / linter
gem 'guard-rspec',         require: false
# Markdown provider for yard. kramdown is pure Ruby on purpose: redcarpet
# ships a C extension that JRuby cannot build, which fails `bundle install`
# on that CI job long before any spec runs.
gem 'kramdown',            require: false
gem 'rubocop',             require: false
gem 'rubocop-performance', require: false
gem 'rubocop-rake',        require: false
gem 'rubocop-rspec',       require: false
gem 'yard',                require: false
