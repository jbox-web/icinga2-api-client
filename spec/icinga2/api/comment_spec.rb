# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Comment do

  include WebMock::API

  subject(:comment) { described_class.new(api_client: client, '__name' => 'foo.example.net!ssh!cuuid') }

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  after { WebMock.reset! }

  describe '#to_s' do
    it 'returns the full name' do
      expect(comment.to_s).to eq 'foo.example.net!ssh!cuuid'
    end
  end

  describe '#remove' do
    it 'removes the comment and returns the result' do
      stub_request(:post, %r{/v1/actions/remove-comment}).to_return(
        status: 200, body: '{"results":[{"code":200,"status":"ok"}]}', headers: { 'Content-Type' => 'application/json' }
      )

      expect(comment.remove).to be_a(Hash)
    end

    it 'raises when nothing is removed' do
      stub_request(:post, %r{/v1/actions/remove-comment})
        .to_return(status: 200, body: '{"results":[]}', headers: { 'Content-Type' => 'application/json' })

      expect { comment.remove }.to raise_error(Icinga2::API::Error)
    end
  end
end
