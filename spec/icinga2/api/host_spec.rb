# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Host do

  subject(:host) { client.hosts.find('foo.example.net') }

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  describe '#api_client' do
    it 'returns the previous defined client' do
      VCR.use_cassette('single_host') do
        expect(host.api_client).to eq client
      end
    end
  end

  describe '#to_s' do
    it 'returns Icinga2 host name' do
      VCR.use_cassette('single_host') do
        expect(host.to_s).to eq 'foo.example.net'
      end
    end
  end

  describe '#to_h' do
    it 'returns host attributes as a hash' do
      VCR.use_cassette('single_host') do
        expect(host.to_h).to be_a(Hash)
        expect(host.to_h[:name]).to eq 'foo.example.net'
      end
    end
  end

  describe '#name' do
    it 'returns Icinga2 host name' do
      VCR.use_cassette('single_host') do
        expect(host.name).to eq 'foo.example.net'
      end
    end
  end

  describe '#services' do
    it 'returns Icinga2 host services' do
      VCR.use_cassette('single_host_with_services') do
        expect(host.services).to be_a(Icinga2::API::Services)
        expect(host.services.host).to eq host
        expect(host.services.api_client).to eq host.api_client
      end
    end
  end
end
