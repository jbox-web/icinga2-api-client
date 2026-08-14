# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Client do

  subject(:client) { described_class.new('https://icinga2.example.net:5665', icinga_credentials) }

  describe '#base_url / #options' do
    it 'exposes the base url and options' do
      expect(client.base_url).to eq 'https://icinga2.example.net:5665'
      expect(client.options).to eq icinga_credentials
    end
  end

  describe '#api' do
    it 'builds an Interface configured from the options' do
      expect(client.api).to be_a(Icinga2::API::Interface)
      expect(client.api.base_url).to eq 'https://icinga2.example.net:5665'
      expect(client.api.username).to eq 'root'
    end

    it 'memoizes the interface' do
      first = client.api
      expect(client.api).to be(first)
    end
  end

  describe '#status' do
    include WebMock::API

    after { WebMock.reset! }

    it 'returns the status results' do
      stub_request(:get, %r{/v1/status}).to_return(
        status: 200, body: '{"results":[{"name":"IcingaApplication"}]}', headers: { 'Content-Type' => 'application/json' }
      )

      expect(client.status).to eq [{ 'name' => 'IcingaApplication' }]
    end
  end

  describe '#subscribe' do
    include WebMock::API

    after { WebMock.reset! }

    it 'yields events from the stream' do
      stub_request(:post, 'https://icinga2.example.net:5665/v1/events')
        .to_return(status: 200, body: "{\"type\":\"CheckResult\"}\n", headers: { 'Content-Type' => 'application/json' })

      events = []
      client.subscribe(types: 'CheckResult', queue: 'q') { |event| events << event }

      expect(events).to eq [{ 'type' => 'CheckResult' }]
    end
  end

  describe '#hosts' do
    it 'returns a Hosts collection bound to the client' do
      expect(client.hosts).to be_a(Icinga2::API::Hosts)
      expect(client.hosts.api_client).to be(client)
    end

    it 'memoizes the collection' do
      first = client.hosts
      expect(client.hosts).to be(first)
    end
  end

  describe '#objects' do
    it 'returns a generic collection for any catalogued type' do
      collection = client.objects(:notification)
      expect(collection).to be_a(Icinga2::API::Objects)
      expect(collection.type.endpoint).to eq 'notifications'
    end

    it 'memoizes per type' do
      users = client.objects(:user)
      expect(client.objects(:user)).to be(users)
      expect(client.objects(:user_group)).not_to be(users)
    end

    it 'raises on a type the catalog does not carry' do
      expect { client.objects(:zone) }.to raise_error(Icinga2::API::Error::UnknownType)
    end
  end

  describe 'the named collections' do
    {
      notifications:       'notifications',
      users:               'users',
      user_groups:         'usergroups',
      time_periods:        'timeperiods',
      host_groups:         'hostgroups',
      service_groups:      'servicegroups',
      dependencies:        'dependencies',
      scheduled_downtimes: 'scheduleddowntimes'
    }.each do |method, endpoint|
      it "##{method} targets /#{endpoint}" do
        expect(client.public_send(method).type.endpoint).to eq endpoint
      end
    end
  end
end
