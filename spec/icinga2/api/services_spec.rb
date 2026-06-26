# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Services do

  subject(:all_services) { client.hosts.find('foo.example.net').services }

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  describe 'freshness' do
    include WebMock::API

    subject(:services) { described_class.new(api_client: client, host: host) }

    let(:host) { Icinga2::API::Host.new(name: 'foo.example.net', api_client: client) }

    after { WebMock.reset! }

    it 'refetches services on every #all call (no stale cache)' do
      headers = { 'Content-Type' => 'application/json' }
      stub_request(:get, %r{/v1/objects/services}).to_return(
        { status: 200, body: '{"results":[{"attrs":{"name":"a"}}]}', headers: headers },
        { status: 200, body: '{"results":[{"attrs":{"name":"b"}}]}', headers: headers }
      )

      expect(services.all.map(&:name)).to eq ['a']
      expect(services.all.map(&:name)).to eq ['b']
    end
  end

  describe '#all' do
    it 'returns all Icinga2 services for the host' do
      VCR.use_cassette('single_host_with_services') do
        services = all_services.all
        expect(services.size).to eq 2
        expect(services.first.to_s).to eq 'foo.example.net!dockerd|daemon'
      end
    end
  end

  describe '#find' do
    context 'when Icinga2 service host exist' do
      it 'returns service object' do
        VCR.use_cassette('single_host_with_services') do
          service = all_services.find('dockerd|daemon')
          expect(service).to be_a(Icinga2::API::Service)
          expect(service.to_s).to eq 'foo.example.net!dockerd|daemon'
        end
      end
    end

    context 'when Icinga2 service host dont exist' do
      it 'returns nil' do
        VCR.use_cassette('single_host_with_services') do
          expect(all_services.find('foo')).to be_nil
        end
      end
    end
  end

  describe '#downtimes' do
    context 'when Icinga2 no downtimes exist' do
      it 'returns empty array' do
        VCR.use_cassette('single_host_without_downtimes') do
          downtimes = all_services.downtimes

          expect(downtimes).to be_a(Array)
          expect(downtimes.size).to eq 0
        end
      end
    end

    context 'when Icinga2 downtimes exist' do
      it 'returns all Icinga2 services downtimes for the host' do
        VCR.use_cassette('single_host_with_downtimes') do
          create_downtime('foo.example.net', 'dockerd|daemon')
          downtimes = all_services.downtimes

          expect(downtimes.size).to eq 1
          expect(downtimes.first.to_s).to include('foo.example.net!dockerd|daemon')
        end
      end

      it 'associates each downtime with its service' do
        VCR.use_cassette('single_host_with_downtimes') do
          create_downtime('foo.example.net', 'dockerd|daemon')
          downtime = all_services.downtimes.first

          expect(downtime.service).to be_a(Icinga2::API::Service)
          expect(downtime.service.name).to eq 'dockerd|daemon'
        end
      end
    end
  end
end
