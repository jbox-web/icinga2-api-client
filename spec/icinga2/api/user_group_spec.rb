# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::UserGroup do

  include WebMock::API

  subject(:group) do
    described_class.new(api_client: client, icinga_type: 'UserGroup', '__name' => 'oncall', 'groups' => %w[staff])
  end

  after { WebMock.reset! }


  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:base)   { 'https://icinga2.example.net:5665/v1/objects' }

  it 'is named after its Icinga __name' do
    expect(group.to_s).to eq 'oncall'
  end

  describe '#users' do
    # Membership is held on the member, not on the group, and Icinga2 only
    # matches it through .contains() — the `in` operator answers 404 here.
    it 'lists the users holding this group' do
      stub_request(:get, "#{base}/users")
        .with(query: { 'filter' => 'user.groups.contains("oncall")' })
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'admin' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(group.users.map(&:__name)).to eq %w[admin]
    end
  end

  describe '#parent_groups' do
    it 'resolves the groups this group belongs to' do
      stub_request(:get, "#{base}/usergroups")
        .with(query: { 'filter' => 'usergroup.__name=="staff"' })
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'staff' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(group.parent_groups.map(&:__name)).to eq %w[staff]
    end
  end
end
