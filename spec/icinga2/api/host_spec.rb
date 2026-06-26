# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Host do

  subject(:host) { client.hosts.find('foo.example.net') }

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  describe '#schedule_downtime' do
    include WebMock::API

    subject(:built_host) { described_class.new(name: 'foo.example.net', api_client: client) }

    after { WebMock.reset! }

    it 'raises ArgumentError when required parameters are missing' do
      expect { built_host.schedule_downtime(author: 'admin') }.to raise_error(ArgumentError, /comment/)
    end

    it 'returns the created Downtime' do
      stub_request(:post, %r{/v1/actions/schedule-downtime}).to_return(
        status:  200,
        body:    '{"results":[{"code":200,"name":"foo.example.net!uuid","status":"ok"}]}',
        headers: { 'Content-Type' => 'application/json' }
      )

      downtime = built_host.schedule_downtime(author: 'a', comment: 'c', start_time: 1, end_time: 2, duration: 3)
      expect(downtime).to be_a(Icinga2::API::Downtime)
      expect(downtime.full_name).to eq 'foo.example.net!uuid'
    end
  end

  describe '#acknowledge' do
    include WebMock::API

    subject(:built_host) { described_class.new(name: 'foo.example.net', api_client: client) }

    after { WebMock.reset! }

    it 'acknowledges the host problem' do
      stub_request(:post, %r{/v1/actions/acknowledge-problem}).to_return(
        status: 200, body: '{"results":[{"code":200,"status":"ok"}]}', headers: { 'Content-Type' => 'application/json' }
      )

      expect(built_host.acknowledge(author: 'a', comment: 'c')).to be_a(Hash)
    end
  end

  describe '#downtimes' do
    include WebMock::API

    subject(:built_host) { described_class.new(name: 'foo.example.net', api_client: client) }

    after { WebMock.reset! }

    it 'lists the host-level downtimes' do
      body = '{"results":[{"attrs":{"__name":"foo.example.net!uuid","host_name":"foo.example.net"}}]}'
      stub_request(:post, %r{/v1/objects/downtimes})
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

      expect(built_host.downtimes.map(&:full_name)).to eq ['foo.example.net!uuid']
    end
  end

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
