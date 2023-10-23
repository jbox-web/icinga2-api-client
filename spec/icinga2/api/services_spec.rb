require 'spec_helper'

RSpec.describe Icinga2::API::Services do

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  subject { client.hosts.find('foo.example.net').services }

  describe '#all' do
    it 'should return all Icinga2 services for the host' do
      VCR.use_cassette('single_host_with_services', record: :new_episodes) do
        services = subject.all
        expect(services.size).to eq 18
        expect(services.first.to_s).to eq 'foo.example.net!Daemon Bind9'
      end
    end
  end

  describe '#find' do
    context 'when Icinga2 service host exist' do
      it 'should return service object' do
        VCR.use_cassette('single_host_with_services', record: :new_episodes) do
          service = subject.find('ssh')
          expect(service).to be_a(Icinga2::API::Service)
          expect(service.to_s).to eq 'foo.example.net!ssh'
        end
      end
    end

    context 'when Icinga2 service host dont exist' do
      it 'should return nil' do
        VCR.use_cassette('single_host_with_services', record: :new_episodes) do
          expect(subject.find('foo')).to be_nil
        end
      end
    end
  end

  describe '#downtimes' do
    context 'when Icinga2 no downtimes exist' do
      it 'should return empty array' do
        VCR.use_cassette('single_host_without_downtimes') do
          downtimes = subject.downtimes

          expect(downtimes).to be_a(Array)
          expect(downtimes.size).to eq 0
        end
      end
    end

    context 'when Icinga2 downtimes exist' do
      it 'should return all Icinga2 services downtimes for the host' do
        VCR.use_cassette('single_host_with_downtimes', record: :new_episodes) do
          create_downtime('foo.example.net', 'ssh')
          create_downtime('foo.example.net', 'Daemon SyslogNG')
          downtimes = subject.downtimes

          expect(downtimes.size).to eq 2
          expect(downtimes.first.to_s).to include('foo.example.net!ssh')
          expect(downtimes.last.to_s).to include('foo.example.net!Daemon SyslogNG')
        end
      end
    end

  end

end
