# frozen_string_literal: true

require 'spec_helper'

# The collections a Host reaches through the generic object layer. Kept apart
# from host_spec, which is cassette driven, because these are URL and filter
# assertions.
RSpec.describe Icinga2::API::Host do

  include WebMock::API

  after { WebMock.reset! }

  let(:client)  { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:base)    { 'https://icinga2.example.net:5665/v1/objects' }
  let(:host)    { described_class.new(api_client: client, 'name' => 'web01', 'groups' => %w[linux]) }
  let(:service) do
    Icinga2::API::Service.new(api_client: client, host: host, 'name' => 'ssh', 'groups' => %w[remote])
  end

  def stub_objects(endpoint, filter, results)
    stub_request(:get, "#{base}/#{endpoint}")
      .with(query: { 'filter' => filter })
      .to_return(status: 200, body: { results: results }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe 'Host#notifications' do
    # Same rule as Host#downtimes and Host#comments: host-level objects only.
    # Service notifications are reached through host.services.
    it 'returns host-level notifications only' do
      stub_objects('notifications', 'notification.host_name=="web01"&&notification.service_name==""',
                   [{ 'attrs' => { '__name' => 'web01!mail' } }])

      expect(host.notifications.map(&:__name)).to eq %w[web01!mail]
    end

    it 'threads itself down into the objects built' do
      stub_objects('notifications', 'notification.host_name=="web01"&&notification.service_name==""',
                   [{ 'attrs' => { '__name' => 'web01!mail' } }])

      expect(host.notifications.first.host).to be host
    end
  end

  # A name carrying a double quote would otherwise close the filter string
  # early and produce a filter Icinga2 cannot parse.
  describe 'a host whose name carries a double quote' do
    let(:host) { described_class.new(api_client: client, 'name' => 'we"b01') }

    it 'escapes it in the filter' do
      stub_objects('notifications', 'notification.host_name=="we\\"b01"&&notification.service_name==""', [])
      expect(host.notifications).to eq []
    end

    it 'escapes it in the dependency filter too' do
      stub_objects('dependencies', 'dependency.child_host_name=="we\\"b01"&&dependency.child_service_name==""', [])
      expect(host.dependencies).to eq []
    end
  end

  describe 'Host#scheduled_downtimes' do
    it 'returns host-level rules only' do
      stub_objects('scheduleddowntimes',
                   'scheduleddowntime.host_name=="web01"&&scheduleddowntime.service_name==""',
                   [{ 'attrs' => { '__name' => 'web01!nightly' } }])

      expect(host.scheduled_downtimes.map(&:__name)).to eq %w[web01!nightly]
    end
  end

  describe 'Host#dependencies' do
    it 'returns the dependencies this host is the child of' do
      stub_objects('dependencies', 'dependency.child_host_name=="web01"&&dependency.child_service_name==""',
                   [{ 'attrs' => { '__name' => 'web01!needs-router' } }])

      expect(host.dependencies.map(&:__name)).to eq %w[web01!needs-router]
    end
  end

  describe 'Host#host_groups' do
    it 'resolves the group names into objects' do
      stub_objects('hostgroups', 'hostgroup.__name=="linux"', [{ 'attrs' => { '__name' => 'linux' } }])
      expect(host.host_groups.map(&:__name)).to eq %w[linux]
    end

    it 'leaves #groups returning the raw names' do
      expect(host.groups).to eq %w[linux]
    end
  end
end
