# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
task default: :spec

# Documentation. Loaded lazily so a missing yard never breaks `rake spec`.
begin
  require 'yard'

  YARD::Rake::YardocTask.new(:doc)

  desc 'Report documentation coverage and list what is still undocumented'
  task :'doc:stats' do
    sh 'yard stats --list-undoc'
  end
rescue LoadError
  nil
end

Dir[File.expand_path('tasks/*.rake', __dir__)].each { |task| load task }
