require 'simplecov'
require 'rspec'
require 'vcr'

# Start Simplecov
SimpleCov.start do
  add_filter 'spec/'
end

# Configure VCR
VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into            :webmock
end

require 'icinga2/api'

def create_downtime(host, service)
  duration   = 5.minute
  start_time = DateTime.now
  end_time   = start_time + duration

  client.hosts
        .find(host)
        .services
        .find(service)
        .schedule_downtime(
          author:     'admin',
          comment:    'It will be down for a while, thank you!',
          start_time: start_time.to_i,
          end_time:   end_time.to_i,
          duration:   duration.to_i
        )
end
