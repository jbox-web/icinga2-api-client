# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::User do

  include WebMock::API

  subject(:user) do
    described_class.new(api_client: client, icinga_type: 'User',
                        '__name' => 'admin', 'groups' => %w[oncall], 'period' => '24x7')
  end

  after { WebMock.reset! }


  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:base)   { 'https://icinga2.example.net:5665/v1/objects' }

  def stub_lookup(endpoint, filter, name)
    stub_request(:get, "#{base}/#{endpoint}")
      .with(query: { 'filter' => filter })
      .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => name } }] }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  it 'is named after its Icinga __name' do
    expect(user.to_s).to eq 'admin'
  end

  describe 'raw attributes' do
    it 'keeps #groups returning the names the API sent' do
      expect(user.groups).to eq %w[oncall]
    end
  end

  describe '#user_groups' do
    it 'resolves the groups into objects' do
      stub_lookup('usergroups', 'usergroup.__name=="oncall"', 'oncall')
      expect(user.user_groups.map(&:__name)).to eq %w[oncall]
    end
  end

  describe '#time_period' do
    it 'resolves the period' do
      stub_lookup('timeperiods', 'timeperiod.__name=="24x7"', '24x7')
      expect(user.time_period).to be_an_instance_of Icinga2::API::TimePeriod
    end
  end
end
