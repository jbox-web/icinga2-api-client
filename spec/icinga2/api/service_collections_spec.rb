# frozen_string_literal: true

require 'spec_helper'

# The collections a Service reaches through the generic object layer. Kept
# apart from service_spec, which is cassette driven, because these are URL and
# filter assertions.
RSpec.describe Icinga2::API::Service do

  include WebMock::API

  after { WebMock.reset! }

  let(:client)  { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:base)    { 'https://icinga2.example.net:5665/v1/objects' }
  let(:host)    { Icinga2::API::Host.new(api_client: client, 'name' => 'web01', 'groups' => %w[linux]) }
  let(:service) do
    described_class.new(api_client: client, host: host, 'name' => 'ssh', 'groups' => %w[remote])
  end

  def stub_objects(endpoint, filter, results)
    stub_request(:get, "#{base}/#{endpoint}")
      .with(query: { 'filter' => filter })
      .to_return(status: 200, body: { results: results }.to_json, headers: { 'Content-Type' => 'application/json' })
  end


  describe 'Service#notifications' do
    it 'returns the notifications of that service' do
      stub_objects('notifications', 'notification.host_name=="web01"&&notification.service_name=="ssh"',
                   [{ 'attrs' => { '__name' => 'web01!ssh!mail' } }])

      expect(service.notifications.map(&:__name)).to eq %w[web01!ssh!mail]
    end

    it 'threads host and service down into the objects built' do
      stub_objects('notifications', 'notification.host_name=="web01"&&notification.service_name=="ssh"',
                   [{ 'attrs' => { '__name' => 'web01!ssh!mail' } }])

      notification = service.notifications.first
      expect(notification.host).to be host
      expect(notification.service).to be service
    end
  end

  describe 'a service whose name carries a double quote' do
    let(:service) { described_class.new(api_client: client, host: host, 'name' => 'ss"h') }

    it 'escapes it in the filter' do
      stub_objects('notifications', 'notification.host_name=="web01"&&notification.service_name=="ss\\"h"', [])
      expect(service.notifications).to eq []
    end
  end

  describe 'Service#service_groups' do
    it 'resolves the group names into objects' do
      stub_objects('servicegroups', 'servicegroup.__name=="remote"', [{ 'attrs' => { '__name' => 'remote' } }])
      expect(service.service_groups.map(&:__name)).to eq %w[remote]
    end
  end

  describe 'Service#scheduled_downtimes' do
    it 'returns the rules targeting that service' do
      stub_objects('scheduleddowntimes',
                   'scheduleddowntime.host_name=="web01"&&scheduleddowntime.service_name=="ssh"',
                   [{ 'attrs' => { '__name' => 'web01!ssh!nightly' } }])

      expect(service.scheduled_downtimes.map(&:__name)).to eq %w[web01!ssh!nightly]
    end
  end
end
