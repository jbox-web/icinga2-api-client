# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Interface do

  include WebMock::API

  subject(:interface) do
    described_class.new(base_url: 'https://icinga2.example.net:5665', username: 'root', password: 'root')
  end

  after { WebMock.reset! }

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
  end
end
