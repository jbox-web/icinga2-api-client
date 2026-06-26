# frozen_string_literal: true

require 'spec_helper'

# Read-only integration tests against a real Icinga2 server.
#
# Excluded by default. To run them, define the environment and opt in:
#
#   ICINGA_INTEGRATION=1 \
#   ICINGA_API_URL=https://icinga.example.net:5665 \
#   ICINGA_API_USER=... ICINGA_API_PASSWORD=... \
#   bin/rspec spec/integration
#
# They expect two demo hosts (foo.example.net, bar.example.net), each with the
# services "dockerd|daemon" and "containerd|daemon".
RSpec.describe 'Icinga2 live API', :integration do # rubocop:disable RSpec/DescribeClass

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

  describe 'hosts' do
    it 'lists the demo hosts' do
      names = client.hosts.all.map(&:to_s)
      expect(names).to include('foo.example.net', 'bar.example.net')
    end

    it 'finds an existing host' do
      expect(client.hosts.find('foo.example.net').to_s).to eq 'foo.example.net'
    end

    it 'returns nil for a missing host' do
      expect(client.hosts.find('zzz-does-not-exist-42.invalid')).to be_nil
    end

    it 'lists host-level downtimes' do
      expect(client.hosts.find('foo.example.net').downtimes).to be_a(Array)
    end

    it 'lists host-level comments' do
      expect(client.hosts.find('foo.example.net').comments).to be_a(Array)
    end
  end

  describe 'status' do
    it 'returns the daemon status components' do
      expect(client.status).to be_a(Array).and(be_any)
    end
  end

  describe 'services' do
    subject(:services) { client.hosts.find('foo.example.net').services }

    it 'lists the host services' do
      expect(services.all.map(&:name)).to contain_exactly('dockerd|daemon', 'containerd|daemon')
    end

    it 'finds a service by name' do
      service = services.find('dockerd|daemon')
      expect(service).to be_a(Icinga2::API::Service)
      expect(service.to_s).to eq 'foo.example.net!dockerd|daemon'
    end

    it 'has no downtimes' do
      expect(services.downtimes).to eq []
    end
  end
end
