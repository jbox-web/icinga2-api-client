# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::GenericObject do

  include WebMock::API

  subject(:object) do
    described_class.new(
      api_client:   client,
      icinga_type:  'Notification',
      '__name'      => 'web01!ssh!mail',
      'host_name'   => 'web01',
      'period'      => '24x7',
      'users'       => %w[admin oncall],
      'user_groups' => []
    )
  end

  after { WebMock.reset! }


  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:base)   { 'https://icinga2.example.net:5665/v1/objects' }

  describe '#type' do
    it 'resolves its own catalog entry' do
      expect(object.type.name).to eq 'Notification'
      expect(object.type.endpoint).to eq 'notifications'
    end
  end

  describe '#full_name' do
    it 'is the Icinga __name' do
      expect(object.full_name).to eq 'web01!ssh!mail'
      expect(object.to_s).to eq 'web01!ssh!mail'
    end
  end

  describe 'raw attributes' do
    # Navigation must never shadow an attribute: a caller reading #period today
    # gets a String and has to keep getting one.
    it 'keeps returning what the API sent' do
      expect(object.period).to eq '24x7'
      expect(object.users).to eq %w[admin oncall]
    end
  end

  describe '#navigate' do
    context 'with a single reference' do
      it 'fetches the referenced object' do
        stub_request(:get, "#{base}/hosts")
          .with(query: { 'filter' => 'host.__name=="web01"' })
          .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'web01' } }] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        expect(object.navigate(:host_name)).to be_an_instance_of Icinga2::API::Host
      end

      it 'returns nil when the attribute is empty' do
        empty = described_class.new(api_client: client, icinga_type: 'Notification', 'host_name' => '')
        expect(empty.navigate(:host_name)).to be_nil
      end
    end

    context 'with a list of references' do
      it 'fetches them all in one request' do
        stub_request(:get, "#{base}/users")
          .with(query: { 'filter' => 'user.__name=="admin"||user.__name=="oncall"' })
          .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'admin' } },
                                                    { 'attrs' => { '__name' => 'oncall' } }] }.to_json,
                     headers: { 'Content-Type' => 'application/json' })

        expect(object.navigate(:users).map(&:__name)).to eq %w[admin oncall]
      end

      it 'returns an empty list for an empty attribute' do
        expect(object.navigate(:user_groups)).to eq []
      end
    end

    context 'with a field that declares no reference' do
      # Distinct from UnknownType: the type is perfectly well known, it is the
      # field that points at nothing. Rescuing one should not catch the other.
      it 'raises UnknownRelation rather than silently returning nil' do
        expect {
          object.navigate(:service_name)
        }.to raise_error(Icinga2::API::Error::UnknownRelation, /service_name/)
      end

      it 'is not an UnknownType, so rescuing one does not catch the other' do
        expect(Icinga2::API::Error::UnknownRelation.ancestors).not_to include(Icinga2::API::Error::UnknownType)
        expect(Icinga2::API::Error::UnknownRelation.new).to be_a(Icinga2::API::Error)
      end
    end
  end
end
