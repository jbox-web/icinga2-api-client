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

  describe '#api_client' do
    it 'returns the previous defined client' do
      VCR.use_cassette('single_host_with_downtimes', record: :new_episodes) do
        expect(downtime.api_client).to eq client
      end
    end
  end

  describe '#to_s' do
    it 'returns Icinga2 downtime name' do
      VCR.use_cassette('single_host_with_downtimes', record: :new_episodes) do
        expect(downtime.to_s).to include('foo.example.net!dockerd|daemon')
      end
    end
  end

  describe '#full_name' do
    it 'returns Icinga2 downtime full_name' do
      VCR.use_cassette('single_host_with_downtimes', record: :new_episodes) do
        expect(downtime.full_name).to include('foo.example.net!dockerd|daemon')
      end
    end
  end

  describe '#cancel' do
    it 'cancels Icinga2 downtime' do
      VCR.use_cassette('single_host_cancel_downtimes', record: :new_episodes) do
        expect(downtime.cancel).to be_a(Hash)
      end
    end
  end
end
