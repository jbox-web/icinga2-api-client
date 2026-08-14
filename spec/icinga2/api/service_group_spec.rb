# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::ServiceGroup do

  include WebMock::API

  subject(:group) do
    described_class.new(api_client: client, icinga_type: 'ServiceGroup',
                        '__name' => 'web', 'groups' => %w[all-services])
  end

  after { WebMock.reset! }


  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:base)   { 'https://icinga2.example.net:5665/v1/objects' }

  it 'is named after its Icinga __name' do
    expect(group.to_s).to eq 'web'
  end

  describe '#services' do
    it 'lists the member services through contains()' do
      stub_request(:get, "#{base}/services")
        .with(query: { 'filter' => 'service.groups.contains("web")' })
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'web01!http' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(group.services.map(&:__name)).to eq %w[web01!http]
    end
  end

  describe '#parent_groups' do
    it 'resolves the groups this group belongs to' do
      stub_request(:get, "#{base}/servicegroups")
        .with(query: { 'filter' => 'servicegroup.__name=="all-services"' })
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'all-services' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(group.parent_groups.map(&:__name)).to eq %w[all-services]
    end
  end
end
