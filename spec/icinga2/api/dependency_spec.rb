# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Dependency do

  include WebMock::API

  subject(:dependency) do
    described_class.new(api_client: client, icinga_type: 'Dependency',
                        '__name'           => 'web01!ssh!needs-router',
                        'parent_host_name' => 'router01',
                        'child_host_name'  => 'web01',
                        'period'           => '24x7')
  end

  after { WebMock.reset! }


  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:base)   { 'https://icinga2.example.net:5665/v1/objects' }

  def stub_lookup(endpoint, filter, name)
    stub_request(:get, "#{base}/#{endpoint}")
      .with(query: { 'filter' => filter })
      .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => name } }] }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  it 'is named after its Icinga __name' do
    expect(dependency.to_s).to eq 'web01!ssh!needs-router'
  end

  describe '#parent_host' do
    it 'resolves the parent' do
      stub_lookup('hosts', 'host.__name=="router01"', 'router01')
      expect(dependency.parent_host.__name).to eq 'router01'
    end
  end

  describe '#child_host' do
    it 'resolves the child' do
      stub_lookup('hosts', 'host.__name=="web01"', 'web01')
      expect(dependency.child_host.__name).to eq 'web01'
    end
  end

  # Icinga2 declares no ref_type on parent_service_name / child_service_name,
  # so these two arcs are wired by hand.
  describe '#parent_service and #child_service' do
    subject(:dependency) do
      described_class.new(api_client: client, icinga_type: 'Dependency',
                          'parent_host_name'    => 'router01',
                          'parent_service_name' => 'uplink',
                          'child_host_name'     => 'web01',
                          'child_service_name'  => '')
    end

    it 'resolves the parent service' do
      stub_lookup('services', 'service.__name=="router01!uplink"', 'router01!uplink')
      expect(dependency.parent_service.__name).to eq 'router01!uplink'
    end

    it 'returns nil when the child side is host-level' do
      expect(dependency.child_service).to be_nil
    end
  end

  describe '#time_period' do
    it 'resolves the period' do
      stub_lookup('timeperiods', 'timeperiod.__name=="24x7"', '24x7')
      expect(dependency.time_period).to be_an_instance_of Icinga2::API::TimePeriod
    end
  end
end
