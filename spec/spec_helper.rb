# frozen_string_literal: true

require 'simplecov'
require 'simplecov_json_formatter'
require 'vcr'

# Start Simplecov
SimpleCov.start do
  formatter SimpleCov::Formatter::JSONFormatter
  add_filter 'spec/'
end

# Configure VCR
VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into            :webmock
end

# Configure RSpec
RSpec.configure do |config|
  config.color = true
  config.fail_fast = false

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # disable monkey patching
  # see: https://relishapp.com/rspec/rspec-core/v/3-8/docs/configuration/zero-monkey-patching-mode
  config.disable_monkey_patching!

  config.raise_errors_for_deprecations!
end

def icinga_credentials
  { version: 'v1', username: 'root', password: ENV.fetch('ICINGA_API_PASSWORD', 'root'), verify_ssl: false }
end

def create_downtime(host, service) # rubocop:disable Metrics/MethodLength
  duration   = 300
  start_time = DateTime.now
  end_time   = start_time + duration

  client.hosts
        .find(host)
        .services
        .find(service)
        .schedule_downtime(
          author:     'admin',
          comment:    'It will be down for a while, thank you!',
          start_time: start_time.strftime('%s'),
          end_time:   end_time.strftime('%s'),
          duration:   duration
        )
end

require 'icinga2/api'
