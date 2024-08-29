# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Hosts do

  subject(:all_hosts) { client.hosts }

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  describe '#api_client' do
    it 'returns the previous defined client' do
      expect(all_hosts.api_client).to eq client
    end
  end

  describe '#all' do
    it 'returns all Icinga2 hosts' do
      VCR.use_cassette('all_hosts') do
        # Store the request result to not trigger it
        # multiple times
        hosts = all_hosts.all
        host1 = hosts.first
        host2 = hosts.last

        expect(hosts.size).to eq 2
        expect(host1.name).to eq 'foo.example.net'
        expect(host2.name).to eq 'bar.example.net'
      end
    end
  end

  describe '#find' do
    context 'when Icinga2 host exist' do
      it 'returns host object' do
        VCR.use_cassette('find_existing_host') do
          # Store the request result to not trigger it
          # multiple times
          host = all_hosts.find('foo.example.net')

          expect(host).to be_a(Icinga2::API::Host)
          expect(host.to_s).to eq 'foo.example.net'
          expect(host.api_client).to eq client
        end
      end
    end

    context 'when Icinga2 host dont exist' do
      it 'returns nil' do
        VCR.use_cassette('find_null_host') do
          # Store the request result to not trigger it
          # multiple times
          host = all_hosts.find('baz.example.net')
          expect(host).to be_nil
        end
      end
    end
  end
end
