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
end
