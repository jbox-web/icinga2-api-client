# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Service do

  subject(:service) { client.hosts.find('foo.example.net').services.find('dockerd|daemon') }

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  describe '#schedule_downtime' do
    subject(:built_service) do
      host = Icinga2::API::Host.new(name: 'foo.example.net', api_client: client)
      described_class.new(api_client: client, host: host, '__name' => 'foo.example.net!ssh', 'name' => 'ssh')
    end

    it 'raises ArgumentError when required parameters are missing' do
      expect { built_service.schedule_downtime(author: 'admin') }
        .to raise_error(ArgumentError, /comment/)
    end

    context 'when the downtime is scheduled' do
      include WebMock::API

      after { WebMock.reset! }

      it 'returns the created Downtime' do
        stub_request(:post, %r{/v1/actions/schedule-downtime}).to_return(
          status:  200,
          body:    '{"results":[{"code":200,"name":"foo.example.net!ssh!uuid","status":"ok"}]}',
          headers: { 'Content-Type' => 'application/json' }
        )

        downtime = built_service.schedule_downtime(author: 'a', comment: 'c', start_time: 1, end_time: 2, duration: 3)
        expect(downtime).to be_a(Icinga2::API::Downtime)
        expect(downtime.full_name).to eq 'foo.example.net!ssh!uuid'
      end
    end
  end

  describe '#api_client' do
    it 'returns the previous defined client' do
      VCR.use_cassette('single_host_with_services') do
        expect(service.api_client).to eq client
      end
    end
  end

  describe '#to_s' do
    it 'returns Icinga2 service name' do
      VCR.use_cassette('single_host_with_services') do
        expect(service.to_s).to eq 'foo.example.net!dockerd|daemon'
      end
    end
  end

  describe '#to_h' do
    it 'returns service attributes as a hash' do
      VCR.use_cassette('single_host_with_services') do
        expect(service.to_h).to be_a(Hash)
        expect(service.to_h[:name]).to eq 'dockerd|daemon'
      end
    end
  end

  describe '#full_name' do
    it 'returns Icinga2 service full_name' do
      VCR.use_cassette('single_host_with_services') do
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
        VCR.use_cassette('service_with_downtimes') do
          create_downtime('foo.example.net', 'dockerd|daemon')
          downtimes = service.downtimes

          expect(downtimes.size).to eq 1
          expect(downtimes.first.to_s).to include('foo.example.net!dockerd|daemon')
        end
      end
    end
  end
end
