require 'spec_helper'

RSpec.describe Icinga2::API::Downtime do

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  subject do
    create_downtime('foo.example.net', 'dockerd|daemon')
    client.hosts
          .find('foo.example.net')
          .services
          .find('dockerd|daemon')
          .downtimes
          .first
  end

  describe '#api_client' do
    it 'should return the previous defined client' do
      VCR.use_cassette('single_host_with_downtimes', record: :new_episodes) do
        expect(subject.api_client).to eq client
      end
    end
  end

  describe '#to_s' do
    it 'should return Icinga2 downtime name' do
      VCR.use_cassette('single_host_with_downtimes', record: :new_episodes) do
        expect(subject.to_s).to include('foo.example.net!dockerd|daemon')
      end
    end
  end

  describe '#full_name' do
    it 'should return Icinga2 downtime full_name' do
      VCR.use_cassette('single_host_with_downtimes', record: :new_episodes) do
        expect(subject.full_name).to include('foo.example.net!dockerd|daemon')
      end
    end
  end

  describe '#cancel' do
    it 'should cancel Icinga2 downtime' do
      VCR.use_cassette('single_host_cancel_downtimes', record: :new_episodes) do
        expect(subject.cancel).to be_a(Hash)
      end
    end
  end
end
