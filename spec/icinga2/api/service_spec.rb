require 'spec_helper'

RSpec.describe Icinga2::API::Service do

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  subject { client.hosts.find('foo.example.net').services.find('ssh') }

  describe '#api_client' do
    it 'should return the previous defined client' do
      VCR.use_cassette('single_host_with_services', record: :new_episodes) do
        expect(subject.api_client).to eq client
      end
    end
  end

  describe '#to_s' do
    it 'should return Icinga2 service name' do
      VCR.use_cassette('single_host_with_services', record: :new_episodes) do
        expect(subject.to_s).to eq 'foo.example.net!ssh'
      end
    end
  end

  describe '#to_h' do
    it 'should return service attributes as a hash' do
      VCR.use_cassette('single_host_with_services', record: :new_episodes) do
        expect(subject.to_h).to be_a(Hash)
        expect(subject.to_h[:name]).to eq 'ssh'
      end
    end
  end

  describe '#full_name' do
    it 'should return Icinga2 service full_name' do
      VCR.use_cassette('single_host_with_services', record: :new_episodes) do
        expect(subject.full_name).to eq 'foo.example.net!ssh'
      end
    end
  end

  describe '#downtimes' do
    context 'when Icinga2 no downtimes exist' do
      it 'should return empty array' do
        VCR.use_cassette('service_without_downtimes') do
          downtimes = subject.downtimes
          expect(downtimes).to be_a(Array)
          expect(downtimes.size).to eq 0
        end
      end
    end

    context 'when Icinga2 downtimes exist' do
      it 'should return all Icinga2 downtimes for the service' do
        VCR.use_cassette('service_with_downtimes', record: :new_episodes) do
          create_downtime('foo.example.net', 'ssh')
          create_downtime('foo.example.net', 'Daemon SyslogNG')
          downtimes = subject.downtimes

          expect(downtimes.size).to eq 1
          expect(downtimes.first.to_s).to include('foo.example.net!ssh')
        end
      end
    end
  end

end
