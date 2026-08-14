# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Objects do

  include WebMock::API

  subject(:objects) { described_class.new(api_client: client, type: :notification, catalog: catalog) }

  after { WebMock.reset! }


  let(:client)  { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:catalog) { Icinga2::API::TypeCatalog.new(File.expand_path('../../fixtures/type_catalog.json', __dir__)) }
  let(:base)    { 'https://icinga2.example.net:5665/v1/objects' }

  def stub_objects(query, results)
    stub_request(:get, "#{base}/notifications#{query}")
      .to_return(status: 200, body: { results: results }.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#all' do
    it 'gets the endpoint derived from the type' do
      stub_objects('', [{ 'attrs' => { '__name' => 'web01!ssh!mail' } }])
      expect(objects.all.map(&:__name)).to eq ['web01!ssh!mail']
    end

    it 'passes the filter through' do
      stub_request(:get, "#{base}/notifications")
        .with(query: { 'filter' => 'notification.host_name=="web01"' })
        .to_return(status: 200, body: '{"results":[]}', headers: { 'Content-Type' => 'application/json' })
      expect(objects.all(filter: 'notification.host_name=="web01"')).to eq []
    end

    # Guards the repeated-key form: the bracketed one is silently ignored by
    # Icinga2, which answers with every attribute instead.
    it 'serialises attrs and joins as repeated keys' do
      stub_objects('?attrs=__name&attrs=period&joins=host.name', [])
      expect(objects.all(attrs: %w[__name period], joins: ['host.name'])).to eq []
    end

    it 'skips results carrying no attrs' do
      stub_objects('', [{ 'attrs' => { '__name' => 'a' } }, { 'joins' => {} }])
      expect(objects.all.size).to eq 1
    end

    # The budget is spent on the encoded request line, not on the raw bytes:
    # a double quote costs three characters once escaped, so measuring the raw
    # string underestimates by up to a factor of three and lets a query the
    # server would reject go out as a GET.
    context 'when percent-encoding is what pushes the query past the budget' do
      # 1 064 raw bytes — well under the budget — but 2 110 once encoded,
      # because each of the 520 double quotes costs three characters.
      let(:quoted_filter) { %(notification.host_name=="#{'a"' * 520}") }

      it 'measures the encoded length and posts' do
        stub_request(:post, "#{base}/notifications")
          .with(body: { filter: quoted_filter }.to_json, headers: { 'X-HTTP-Method-Override' => 'GET' })
          .to_return(status: 200, body: '{"results":[]}', headers: { 'Content-Type' => 'application/json' })

        expect(objects.all(filter: quoted_filter)).to eq []
      end
    end

    context 'when the query grows past the URL budget' do
      let(:long_filter) { "notification.host_name==\"#{'x' * 2100}\"" }

      # Icinga2 rejects over-long URLs, so the request flips to POST with the
      # method-override header rather than failing.
      it 'posts with the GET method override instead' do
        stub_request(:post, "#{base}/notifications")
          .with(body: { filter: long_filter }.to_json, headers: { 'X-HTTP-Method-Override' => 'GET' })
          .to_return(status: 200, body: '{"results":[]}', headers: { 'Content-Type' => 'application/json' })

        expect(objects.all(filter: long_filter)).to eq []
      end
    end
  end

  describe '#find' do
    it 'filters on __name and returns the single object' do
      stub_request(:get, "#{base}/notifications")
        .with(query: { 'filter' => 'notification.__name=="web01!ssh!mail"' })
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'web01!ssh!mail' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(objects.find('web01!ssh!mail').__name).to eq 'web01!ssh!mail'
    end

    it 'escapes double quotes in the name' do
      stub_request(:get, "#{base}/notifications")
        .with(query: { 'filter' => 'notification.__name=="we\\"b"' })
        .to_return(status: 200, body: '{"results":[]}', headers: { 'Content-Type' => 'application/json' })

      expect(objects.find('we"b')).to be_nil
    end

    # A filter matching nothing answers 404 "No objects found", which is an
    # empty set rather than a transport failure.
    it 'returns nil when the server answers 404' do
      stub_request(:get, "#{base}/notifications")
        .with(query: { 'filter' => 'notification.__name=="nope"' })
        .to_return(status: 404, body: '{"error":404,"status":"No objects found."}',
                   headers: { 'Content-Type' => 'application/json' })

      expect(objects.find('nope')).to be_nil
    end
  end

  describe '#find_many' do
    # Icinga2's `in` operator tests membership of a value in one of the
    # object's own arrays, so it cannot match a name against a list: verified
    # against a live master, `user.name in ["a","b"]` answers 404. A disjunction
    # does resolve the whole batch in a single request.
    it 'resolves every name in one request, as a disjunction' do
      stub_request(:get, "#{base}/notifications")
        .with(query: { 'filter' => 'notification.__name=="a"||notification.__name=="b"' })
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'b' } },
                                                  { 'attrs' => { '__name' => 'a' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(objects.find_many(%w[a b]).map(&:__name)).to eq %w[a b]
    end

    it 'preserves the requested order and drops what the server did not return' do
      stub_request(:get, "#{base}/notifications")
        .with(query: { 'filter' => 'notification.__name=="a"||notification.__name=="gone"' })
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'a' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      expect(objects.find_many(%w[a gone]).map(&:__name)).to eq %w[a]
    end

    it 'sends no request for an empty list' do
      expect(objects.find_many([])).to eq []
    end

    it 'returns an empty list when the server answers 404' do
      stub_request(:get, "#{base}/notifications")
        .with(query: { 'filter' => 'notification.__name=="nope"' })
        .to_return(status: 404, body: '{"error":404}', headers: { 'Content-Type' => 'application/json' })

      expect(objects.find_many(%w[nope])).to eq []
    end
  end

  describe 'the class of the objects built' do
    it 'uses the dedicated class when one exists' do
      stub_request(:get, "#{base}/hosts")
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'web01' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      hosts = described_class.new(api_client: client, type: :host, catalog: catalog)
      expect(hosts.all.first).to be_an_instance_of Icinga2::API::Host
    end

    it 'falls back to GenericObject for a type with no dedicated class' do
      stub_request(:get, "#{base}/widgets")
        .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => 'w' } }] }.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      widgets = described_class.new(api_client: client, type: :widget, catalog: catalog)
      expect(widgets.all.first).to be_an_instance_of Icinga2::API::GenericObject
    end
  end

  describe 'context threading' do
    let(:host) { Icinga2::API::Host.new(api_client: client, name: 'web01') }

    it 'merges the given context into every object built' do
      stub_objects('', [{ 'attrs' => { '__name' => 'a' } }])
      scoped = described_class.new(api_client: client, type: :notification, catalog: catalog, context: { host: host })
      expect(scoped.all.first.host).to be host
    end
  end

  describe 'an unknown type' do
    it 'raises before any request is sent' do
      expect {
        described_class.new(api_client: client, type: :nope, catalog: catalog)
      }.to raise_error(Icinga2::API::Error::UnknownType)
    end
  end
end
