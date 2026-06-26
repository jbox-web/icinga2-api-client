# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Interface do

  include WebMock::API

  subject(:interface) do
    described_class.new(base_url: 'https://icinga2.example.net:5665', username: 'root', password: 'root')
  end

  after { WebMock.reset! }

  describe 'option validation' do
    it 'rejects unknown options' do
      expect {
        described_class.new(base_url: 'x', username: 'u', password: 'p', verify_ssl: false)
      }.to raise_error(ArgumentError, /verify_ssl/)
    end
  end

  describe 'error translation' do
    def stub_status(code, body = '{}')
      stub_request(:get, 'https://icinga2.example.net:5665/v1/objects/hosts')
        .to_return(status: code, body: body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'raises Icinga2::API::Error::NotFound on 404' do
      stub_status(404, '{"error":404,"status":"No objects found."}')
      expect { interface.get('/objects/hosts') }.to raise_error(Icinga2::API::Error::NotFound)
    end

    it 'raises Icinga2::API::Error::ClientError on other 4xx' do
      stub_status(422)
      expect { interface.get('/objects/hosts') }.to raise_error(Icinga2::API::Error::ClientError)
    end

    it 'raises Icinga2::API::Error::ServerError on 5xx' do
      stub_status(500)
      expect { interface.get('/objects/hosts') }.to raise_error(Icinga2::API::Error::ServerError)
    end

    it 'uses a common Icinga2::API::Error ancestor' do
      stub_status(500)
      expect { interface.get('/objects/hosts') }.to raise_error(Icinga2::API::Error)
    end

    it 'exposes the HTTP response on the raised error' do
      stub_status(404, '{"error":404}')
      expect { interface.get('/objects/hosts') }.to raise_error(Icinga2::API::Error) do |error|
        expect(error.response[:status]).to eq 404
      end
    end
  end

  describe 'request URL building' do
    # The stub only matches when the path/version/query are built exactly right,
    # so a successful call proves the URL was assembled as expected.
    it 'prefixes the path with the API version' do
      stub_request(:get, 'https://icinga2.example.net:5665/v1/objects/services')
        .to_return(status: 200, body: '{"results":[]}', headers: { 'Content-Type' => 'application/json' })
      expect(interface.get('/objects/services')).to eq []
    end

    it 'appends the query hash as an encoded query string' do
      stub_request(:get, 'https://icinga2.example.net:5665/v1/objects/services')
        .with(query: { 'filter' => 'service.host_name=="web01"' })
        .to_return(status: 200, body: '{"results":[]}', headers: { 'Content-Type' => 'application/json' })
      expect(interface.get('/objects/services', query: { filter: 'service.host_name=="web01"' })).to eq []
    end
  end

  describe '#stream' do
    it 'yields each newline-delimited JSON event' do
      body = "{\"type\":\"a\"}\n{\"type\":\"b\"}\n"
      stub_request(:post, 'https://icinga2.example.net:5665/v1/events')
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

      events = []
      interface.stream('/events', params: { types: ['CheckResult'], queue: 'q' }) { |event| events << event }

      expect(events).to eq [{ 'type' => 'a' }, { 'type' => 'b' }]
    end
  end

  describe '#post' do
    it 'sends params as a JSON body and merges the given headers' do
      stub_request(:post, 'https://icinga2.example.net:5665/v1/objects/downtimes')
        .with(body: '{"filter":"x"}', headers: { 'X-HTTP-Method-Override' => 'GET' })
        .to_return(status: 200, body: '{"results":[]}', headers: { 'Content-Type' => 'application/json' })

      result = interface.post('/objects/downtimes', params: { filter: 'x' }, headers: { 'X-HTTP-Method-Override' => 'GET' })
      expect(result).to eq []
    end
  end

  describe 'result extraction' do
    def stub_get(body)
      stub_request(:get, 'https://icinga2.example.net:5665/v1/objects/hosts')
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'returns the results array' do
      stub_get('{"results":[{"attrs":{}}]}')
      expect(interface.get('/objects/hosts')).to eq [{ 'attrs' => {} }]
    end

    it 'returns an empty array when the body has no results key' do
      stub_get('{"error":404,"status":"No objects found."}')
      expect(interface.get('/objects/hosts')).to eq []
    end

    it 'returns an empty array when the body is empty' do
      stub_get('')
      expect(interface.get('/objects/hosts')).to eq []
    end
  end

  describe 'transport failures' do
    it 'raises Icinga2::API::Error::Timeout on a Faraday timeout' do
      stub_request(:get, 'https://icinga2.example.net:5665/v1/objects/hosts').to_raise(Faraday::TimeoutError)
      expect { interface.get('/objects/hosts') }.to raise_error(Icinga2::API::Error::Timeout)
    end

    it 'raises Icinga2::API::Error::ConnectionFailed when the connection fails' do
      stub_request(:get, 'https://icinga2.example.net:5665/v1/objects/hosts').to_raise(Faraday::ConnectionFailed.new('refused'))
      expect { interface.get('/objects/hosts') }.to raise_error(Icinga2::API::Error::ConnectionFailed)
    end
  end

  describe 'logging configuration' do
    subject(:interface) do
      described_class.new(
        base_url: 'https://icinga2.example.net:5665', username: 'root', password: 'root',
        logging: { enabled: true, logger: custom_logger, options: { bodies: true } }
      )
    end

    let(:custom_logger) { Object.new }

    it 'exposes the configured logging settings' do
      expect(interface.enable_logs).to be true
      expect(interface.logger).to eq custom_logger
      expect(interface.logger_options).to eq({ bodies: true })
    end
  end

  describe 'timeouts' do
    it 'applies the configured timeouts to the underlying connection' do
      iface = described_class.new(
        base_url: 'https://icinga2.example.net:5665', username: 'root', password: 'root',
        open_timeout: 3, timeout: 7
      )
      connection = iface.send(:client)

      expect(connection.options.open_timeout).to eq 3
      expect(connection.options.timeout).to eq 7
    end

    it 'defaults the read timeout to 30 seconds' do
      expect(interface.send(:client).options.timeout).to eq 30
    end
  end
end
