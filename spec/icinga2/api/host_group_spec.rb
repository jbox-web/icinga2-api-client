# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::HostGroup do

  include WebMock::API

  subject(:group) do
    described_class.new(api_client: client, icinga_type: 'HostGroup',
                        '__name' => 'checks-snmp', 'groups' => %w[servers-all])
  end

  after { WebMock.reset! }


  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:base)   { 'https://icinga2.example.net:5665/v1/objects' }

  it 'is named after its Icinga __name' do
    expect(group.to_s).to eq 'checks-snmp'
  end

  describe '#hosts' do
    # Verified against a live master: `"grp" in host.groups` answers 404,
    # `host.groups.contains("grp")` returns the members.
    it 'lists the member hosts through contains()' do
      stub_request(:get, "#{base}/hosts")
        .with(query: { 'filter' => 'host.groups.contains("checks-snmp")' })
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'forti01' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(group.hosts.map(&:__name)).to eq %w[forti01]
    end
  end

  describe 'a group whose name carries a double quote' do
    subject(:group) do
      described_class.new(api_client: client, icinga_type: 'HostGroup', '__name' => 'ch"ecks')
    end

    it 'escapes it in the membership filter' do
      stub_request(:get, "#{base}/hosts")
        .with(query: { 'filter' => 'host.groups.contains("ch\\"ecks")' })
        .to_return(status: 200, body: '{"results":[]}', headers: { 'Content-Type' => 'application/json' })

      expect(group.hosts).to eq []
    end
  end

  describe '#parent_groups' do
    it 'resolves the groups this group belongs to' do
      stub_request(:get, "#{base}/hostgroups")
        .with(query: { 'filter' => 'hostgroup.__name=="servers-all"' })
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'servers-all' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(group.parent_groups.map(&:__name)).to eq %w[servers-all]
    end
  end
end
