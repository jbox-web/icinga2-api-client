require 'spec_helper'

RSpec.describe Icinga2::API::Host do

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  subject { client.hosts.find('foo.example.net') }

  describe '#api_client' do
    it 'should return the previous defined client' do
      VCR.use_cassette('single_host') do
        expect(subject.api_client).to eq client
      end
    end
  end

  describe '#to_s' do
    it 'should return Icinga2 host name' do
      VCR.use_cassette('single_host') do
        expect(subject.to_s).to eq 'foo.example.net'
      end
    end
  end

  describe '#to_h' do
    it 'should return host attributes as a hash' do
      VCR.use_cassette('single_host') do
        expect(subject.to_h).to be_a(Hash)
        expect(subject.to_h[:name]).to eq 'foo.example.net'
      end
    end
  end

  describe '#name' do
    it 'should return Icinga2 host name' do
      VCR.use_cassette('single_host') do
        expect(subject.to_s).to eq 'foo.example.net'
      end
    end
  end

  describe '#services' do
    it 'should return Icinga2 host services' do
      VCR.use_cassette('single_host_with_services') do
        expect(subject.services).to be_a(Icinga2::API::Services)
        expect(subject.services.host).to eq subject
        expect(subject.services.api_client).to eq subject.api_client
      end
    end
  end

end
