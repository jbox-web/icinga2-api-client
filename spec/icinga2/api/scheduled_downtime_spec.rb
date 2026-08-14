# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::ScheduledDowntime do

  include WebMock::API

  subject(:scheduled) do
    described_class.new(api_client: client, icinga_type: 'ScheduledDowntime',
                        '__name' => 'web01!nightly', 'host_name' => 'web01')
  end

  after { WebMock.reset! }


  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:base)   { 'https://icinga2.example.net:5665/v1/objects' }

  it 'is named after its Icinga __name' do
    expect(scheduled.to_s).to eq 'web01!nightly'
  end

  describe '#host' do
    it 'resolves the host' do
      stub_request(:get, "#{base}/hosts")
        .with(query: { 'filter' => 'host.__name=="web01"' })
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'web01' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(scheduled.host).to be_an_instance_of Icinga2::API::Host
    end
  end

  describe '#service' do
    it 'resolves the service when the rule targets one' do
      on_service = described_class.new(api_client: client, icinga_type: 'ScheduledDowntime',
                                       'host_name' => 'web01', 'service_name' => 'ssh')
      stub_request(:get, "#{base}/services")
        .with(query: { 'filter' => 'service.__name=="web01!ssh"' })
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'web01!ssh' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(on_service.service.__name).to eq 'web01!ssh'
    end

    it 'returns nil for a host-level rule' do
      expect(scheduled.service).to be_nil
    end
  end

  # A ScheduledDowntime is a recurring rule, not an active downtime: it is not
  # what Host#downtimes / Service#downtimes return.
  it 'is not a Downtime' do
    expect(scheduled).not_to be_a Icinga2::API::Downtime
  end
end
