# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Downtime do

  subject(:downtime) do
    create_downtime('foo.example.net', 'dockerd|daemon')
    client.hosts
          .find('foo.example.net')
          .services
          .find('dockerd|daemon')
          .downtimes
          .first
  end

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  describe 'timestamp coercion' do
    it 'converts epoch timestamps to Time' do
      dt = described_class.new(
        api_client: client.api, 'name' => 'd', 'start_time' => 1_700_000_000, 'end_time' => 1_700_000_300
      )
      expect(dt.start_time).to be_a(Time)
      expect(dt.end_time).to be_a(Time)
    end

    it 'does not fabricate timestamps when they are absent' do
      dt = described_class.new(api_client: client.api, 'name' => 'd')
      expect(dt.respond_to?(:start_time)).to be false
    end
  end

  describe '#api_client' do
    it 'returns the previous defined client' do
      VCR.use_cassette('single_host_with_downtimes') do
        expect(downtime.api_client).to eq client
      end
    end
  end

  describe '#to_s' do
    it 'returns Icinga2 downtime name' do
      VCR.use_cassette('single_host_with_downtimes') do
        expect(downtime.to_s).to include('foo.example.net!dockerd|daemon')
      end
    end
  end

  describe '#full_name' do
    it 'returns Icinga2 downtime full_name' do
      VCR.use_cassette('single_host_with_downtimes') do
        expect(downtime.full_name).to include('foo.example.net!dockerd|daemon')
      end
    end
  end

  describe '#cancel' do
    it 'cancels Icinga2 downtime' do
      VCR.use_cassette('single_host_cancel_downtimes') do
        expect(downtime.cancel).to be_a(Hash)
      end
    end

    context 'when the server removes nothing' do
      include WebMock::API

      subject(:lonely_downtime) { described_class.new(api_client: client, '__name' => 'foo.example.net!ssh!uuid') }

      after { WebMock.reset! }

      it 'raises instead of returning nil silently' do
        stub_request(:post, %r{/v1/actions/remove-downtime}).to_return(
          status:  200,
          body:    '{"results":[]}',
          headers: { 'Content-Type' => 'application/json' }
        )
        expect { lonely_downtime.cancel }.to raise_error(Icinga2::API::Error)
      end
    end
  end
end
