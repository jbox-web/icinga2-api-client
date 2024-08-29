# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Service do

  subject(:service) { client.hosts.find('foo.example.net').services.find('dockerd|daemon') }

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  describe '#api_client' do
    it 'returns the previous defined client' do
      VCR.use_cassette('single_host_with_services', record: :new_episodes) do
        expect(service.api_client).to eq client
      end
    end
  end

  describe '#to_s' do
    it 'returns Icinga2 service name' do
      VCR.use_cassette('single_host_with_services', record: :new_episodes) do
        expect(service.to_s).to eq 'foo.example.net!dockerd|daemon'
      end
    end
  end

  describe '#to_h' do
    it 'returns service attributes as a hash' do
      VCR.use_cassette('single_host_with_services', record: :new_episodes) do
        expect(service.to_h).to be_a(Hash)
        expect(service.to_h[:name]).to eq 'dockerd|daemon'
      end
    end
  end

  describe '#full_name' do
    it 'returns Icinga2 service full_name' do
      VCR.use_cassette('single_host_with_services', record: :new_episodes) do
        expect(service.full_name).to eq 'foo.example.net!dockerd|daemon'
      end
    end
  end

  describe '#downtimes' do
    context 'when Icinga2 no downtimes exist' do
      it 'returns empty array' do
        VCR.use_cassette('service_without_downtimes') do
          downtimes = service.downtimes
          expect(downtimes).to be_a(Array)
          expect(downtimes.size).to eq 0
        end
      end
    end

    context 'when Icinga2 downtimes exist' do
      it 'returns all Icinga2 downtimes for the service' do
        VCR.use_cassette('service_with_downtimes', record: :new_episodes) do
          create_downtime('foo.example.net', 'dockerd|daemon')
          downtimes = service.downtimes

          expect(downtimes.size).to eq 1
          expect(downtimes.first.to_s).to include('foo.example.net!dockerd|daemon')
        end
      end
    end
  end
end
