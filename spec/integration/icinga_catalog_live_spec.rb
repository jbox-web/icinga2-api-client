# frozen_string_literal: true

require 'spec_helper'

# Read-only integration tests for the generic object layer, against a real
# Icinga2 server.
#
# Excluded by default. To run them, define the environment and opt in:
#
#   ICINGA_INTEGRATION=1 \
#   ICINGA_API_URL=https://icinga.example.net:5665 \
#   ICINGA_API_USER=... ICINGA_API_PASSWORD=... \
#   bin/rspec spec/integration
#
# Unlike icinga_live_spec.rb these expect no particular object to exist: they
# check the shipped type catalog still matches the server it describes. An
# endpoint or a filter variable the snapshot got wrong answers 404, so a green
# run is the proof that the snapshot is still current.
RSpec.describe 'Icinga2 live catalog', :integration do # rubocop:disable RSpec/DescribeClass

  subject(:client) do
    Icinga2::API::Client.new(
      ENV.fetch('ICINGA_API_URL'),
      version:     'v1',
      username:    ENV.fetch('ICINGA_API_USER'),
      password:    ENV.fetch('ICINGA_API_PASSWORD'),
      ssl_options: { verify: false }
    )
  end

  # Talk to the real server: VCR/WebMock must step aside for these examples.
  around do |example|
    VCR.turned_off do
      WebMock.allow_net_connect!
      example.run
    ensure
      WebMock.disable_net_connect!
    end
  end

  describe 'every catalogued collection' do
    %i[users user_groups time_periods host_groups service_groups dependencies
       scheduled_downtimes notifications].each do |collection|
      it "reaches #{collection} without erroring" do
        expect(client.public_send(collection).all(attrs: ['__name'])).to be_a(Array)
      end
    end
  end

  describe 'attribute restriction' do
    # Icinga2 silently ignores the bracketed form of this parameter and answers
    # with the whole object, so asserting that exactly one attribute came back
    # is what catches a regression in the query serialisation.
    it 'returns only the attributes asked for' do
      host = client.hosts.all.first
      skip 'no host on this server' unless host

      restricted = client.objects(:host).all(filter: %(host.__name=="#{host}"), attrs: ['__name'])
      expect(restricted.first.to_h.keys).to eq [:__name]
    end
  end

  describe 'group membership' do
    it 'resolves a host group to its members' do
      group = client.host_groups.all(attrs: ['__name']).first
      skip 'no host group on this server' unless group

      members = group.hosts
      expect(members).to be_a(Array)
      expect(members.first.to_h[:groups]).to include(group.to_s) if members.any?
    end
  end

  describe 'navigating a notification' do
    it 'resolves the objects it points at' do
      notification = client.notifications.all(attrs: %w[__name users period service_name]).first
      skip 'no notification on this server' unless notification

      expect(notification.notified_users).to be_a(Array)
      period = notification.time_period
      expect(period).to be_nil.or be_a(Icinga2::API::TimePeriod)
    end
  end
end
