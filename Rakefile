# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
task default: :spec

Dir[File.expand_path('tasks/*.rake', __dir__)].each { |task| load task }
