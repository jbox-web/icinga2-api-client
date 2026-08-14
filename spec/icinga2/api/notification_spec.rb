# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Notification do

  include WebMock::API

  subject(:notification) do
    described_class.new(
      api_client:   client,
      icinga_type:  'Notification',
      '__name'      => 'web01!ssh!mail',
      'host_name'   => 'web01',
      'service_name' => 'ssh',
      'period'      => '24x7',
      'command'     => 'mail-service-notification',
      'users'       => %w[admin],
      'user_groups' => %w[oncall]
    )
  end

  after { WebMock.reset! }


  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:base)   { 'https://icinga2.example.net:5665/v1/objects' }

  def stub_lookup(endpoint, filter, name, results = nil)
    results ||= [{ 'attrs' => { '__name' => name } }]
    stub_request(:get, "#{base}/#{endpoint}")
      .with(query: { 'filter' => filter })
      .to_return(status: 200, body: { results: results }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  it 'is named after its Icinga __name' do
    expect(notification.to_s).to eq 'web01!ssh!mail'
  end

  describe '#notified_users' do
    it 'resolves the users' do
      stub_lookup('users', 'user.__name=="admin"', 'admin')
      expect(notification.notified_users.map(&:__name)).to eq %w[admin]
    end
  end

  describe '#notified_user_groups' do
    it 'resolves the user groups' do
      stub_lookup('usergroups', 'usergroup.__name=="oncall"', 'oncall')
      expect(notification.notified_user_groups.map(&:__name)).to eq %w[oncall]
    end
  end

  describe '#time_period' do
    it 'resolves the period' do
      stub_lookup('timeperiods', 'timeperiod.__name=="24x7"', '24x7')
      expect(notification.time_period).to be_an_instance_of Icinga2::API::TimePeriod
    end
  end

  # Icinga2 declares no ref_type on any service_name field, so this arc is
  # wired by hand rather than derived from the catalog.
  describe '#service' do
    it 'resolves the service from host_name and service_name' do
      stub_lookup('services', 'service.__name=="web01!ssh"', 'web01!ssh')
      expect(notification.service).to be_an_instance_of Icinga2::API::Service
    end

    it 'returns nil without a request for a host-level notification' do
      host_level = described_class.new(api_client: client, icinga_type: 'Notification',
                                       'host_name' => 'web01', 'service_name' => '')
      expect(host_level.service).to be_nil
    end
  end

  describe '#host' do
    it 'resolves the host when none was threaded down' do
      stub_lookup('hosts', 'host.__name=="web01"', 'web01')
      expect(notification.host).to be_an_instance_of Icinga2::API::Host
    end

    # A nil result must be memoized too, otherwise every call re-queries a
    # host that is not coming back.
    it 'queries once even when the host does not resolve' do
      stub = stub_lookup('hosts', 'host.__name=="web01"', 'web01', [])

      3.times { notification.host }
      expect { assert_requested(stub, times: 1) }.not_to raise_error
    end

    it 'returns the host it was built from without a request' do
      host   = Icinga2::API::Host.new(api_client: client, name: 'web01')
      scoped = described_class.new(api_client: client, icinga_type: 'Notification', host: host, 'host_name' => 'web01')
      expect(scoped.host).to be host
    end
  end
end
