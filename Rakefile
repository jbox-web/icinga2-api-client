#!/usr/bin/env rake

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
task default: :spec

task :console do
  require 'pry'
  require 'icinga2/api'
  puts 'Loaded Icinga2::API'
  ARGV.clear
  Pry.start
end
