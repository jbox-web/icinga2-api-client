# frozen_string_literal: true

require 'spec_helper'

# WRITE integration tests against a real Icinga2 server.
#
# These MUTATE state (they schedule and then cancel a downtime), so they are
# doubly gated and never run by default. Opt in explicitly:
#
#   ICINGA_INTEGRATION=1 ICINGA_INTEGRATION_WRITE=1 \
#   ICINGA_API_URL=https://icinga.example.net:5665 \
#   ICINGA_API_USER=... ICINGA_API_PASSWORD=... \
#   bin/rspec spec/integration
#
# The downtime cycle is self-cleaning (schedule -> cancel) and targets the
# demo host bar.example.net, so nothing is left behind.
RSpec.describe 'Icinga2 live writes', :integration, :integration_write do # rubocop:disable RSpec/DescribeClass

  subject(:client) do
    Icinga2::API::Client.new(
      ENV.fetch('ICINGA_API_URL'),
      version:     'v1',
      username:    ENV.fetch('ICINGA_API_USER'),
      password:    ENV.fetch('ICINGA_API_PASSWORD'),
      ssl_options: { verify: false }
    )
  end

  around do |example|
    VCR.turned_off do
      WebMock.allow_net_connect!
      example.run
    ensure
      WebMock.disable_net_connect!
    end
  end

  let(:service) { client.hosts.find('bar.example.net').services.find('dockerd|daemon') }

  def schedule_short_downtime
    now = Time.now.to_i
    service.schedule_downtime(
      author: 'icinga2-api-client', comment: 'integration spec',
      start_time: now, end_time: now + 60, duration: 60
    )
  end

  it 'schedules then cancels a service downtime' do
    downtime = schedule_short_downtime

    expect(downtime).to be_a(Icinga2::API::Downtime)
    expect(downtime.cancel).to be_a(Hash)
  end
end
