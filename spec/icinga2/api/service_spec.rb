# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Service do

  subject(:service) { client.hosts.find('foo.example.net').services.find('dockerd|daemon') }

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  let(:built_service) do
    host = Icinga2::API::Host.new(name: 'foo.example.net', api_client: client)
    described_class.new(api_client: client, host: host, '__name' => 'foo.example.net!ssh', 'name' => 'ssh')
  end

  def stub_action(action, body = '{"results":[{"code":200,"status":"ok"}]}')
    stub_request(:post, %r{/v1/actions/#{action}})
      .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })
  end

  describe '#schedule_downtime' do
    it 'raises ArgumentError when required parameters are missing' do
      expect { built_service.schedule_downtime(author: 'admin') }
        .to raise_error(ArgumentError, /comment/)
    end

    context 'when the downtime is scheduled' do
      include WebMock::API

      after { WebMock.reset! }

      it 'returns the created Downtime' do
        stub_action('schedule-downtime', '{"results":[{"code":200,"name":"foo.example.net!ssh!uuid","status":"ok"}]}')

        downtime = built_service.schedule_downtime(author: 'a', comment: 'c', start_time: 1, end_time: 2, duration: 3)
        expect(downtime).to be_a(Icinga2::API::Downtime)
        expect(downtime.full_name).to eq 'foo.example.net!ssh!uuid'
      end
    end
  end

  describe '#acknowledge' do
    include WebMock::API

    after { WebMock.reset! }

    it 'raises ArgumentError when required parameters are missing' do
      expect { built_service.acknowledge(author: 'admin') }.to raise_error(ArgumentError, /comment/)
    end

    it 'acknowledges the problem and returns the result' do
      stub_action('acknowledge-problem')
      expect(built_service.acknowledge(author: 'a', comment: 'c')).to be_a(Hash)
    end
  end

  describe '#remove_acknowledgement' do
    include WebMock::API

    after { WebMock.reset! }

    it 'removes the acknowledgement and returns the result' do
      stub_action('remove-acknowledgement')
      expect(built_service.remove_acknowledgement).to be_a(Hash)
    end
  end

  describe '#add_comment' do
    include WebMock::API

    after { WebMock.reset! }

    it 'raises ArgumentError when required parameters are missing' do
      expect { built_service.add_comment(author: 'admin') }.to raise_error(ArgumentError, /comment/)
    end

    it 'returns the created Comment' do
      stub_action('add-comment', '{"results":[{"code":200,"name":"foo.example.net!ssh!cuuid","status":"ok"}]}')
      comment = built_service.add_comment(author: 'a', comment: 'c')

      expect(comment).to be_a(Icinga2::API::Comment)
      expect(comment.full_name).to eq 'foo.example.net!ssh!cuuid'
    end
  end

  describe '#send_notification' do
    include WebMock::API

    after { WebMock.reset! }

    it 'sends a custom notification and returns the result' do
      stub_action('send-custom-notification')
      expect(built_service.send_notification(author: 'a', comment: 'c')).to be_a(Hash)
    end
  end

  describe '#process_check_result' do
    include WebMock::API

    after { WebMock.reset! }

    it 'raises ArgumentError when required parameters are missing' do
      expect { built_service.process_check_result(exit_status: 2) }.to raise_error(ArgumentError, /plugin_output/)
    end

    it 'submits the check result and returns the result' do
      stub_action('process-check-result')
      expect(built_service.process_check_result(exit_status: 2, plugin_output: 'CRITICAL')).to be_a(Hash)
    end
  end

  describe '#comments' do
    include WebMock::API

    after { WebMock.reset! }

    it 'lists the service comments' do
      body = '{"results":[{"attrs":{"__name":"foo.example.net!ssh!cuuid"}}]}'
      stub_request(:post, %r{/v1/objects/comments})
        .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

      expect(built_service.comments.map(&:full_name)).to eq ['foo.example.net!ssh!cuuid']
    end
  end

  describe '#api_client' do
    it 'returns the previous defined client' do
      VCR.use_cassette('single_host_with_services') do
        expect(service.api_client).to eq client
      end
    end
  end

  describe '#to_s' do
    it 'returns Icinga2 service name' do
      VCR.use_cassette('single_host_with_services') do
        expect(service.to_s).to eq 'foo.example.net!dockerd|daemon'
      end
    end
  end

  describe '#to_h' do
    it 'returns service attributes as a hash' do
      VCR.use_cassette('single_host_with_services') do
        expect(service.to_h).to be_a(Hash)
        expect(service.to_h[:name]).to eq 'dockerd|daemon'
      end
    end
  end

  describe '#full_name' do
    it 'returns Icinga2 service full_name' do
      VCR.use_cassette('single_host_with_services') do
        expect(service.full_name).to eq 'foo.example.net!dockerd|daemon'
      end
    end
  end

  describe '#downtimes' do
    context 'when Icinga2 no downtimes exist' do
      it 'returns empty array' do
        VCR.use_cassette('service_without_downtimes') do
          downtimes = service.downtimes
          expect(downtimes).to be_a(Array)
          expect(downtimes.size).to eq 0
        end
      end
    end

    context 'when Icinga2 downtimes exist' do
      it 'returns all Icinga2 downtimes for the service' do
        VCR.use_cassette('service_with_downtimes') do
          create_downtime('foo.example.net', 'dockerd|daemon')
          downtimes = service.downtimes

          expect(downtimes.size).to eq 1
          expect(downtimes.first.to_s).to include('foo.example.net!dockerd|daemon')
        end
      end
    end
  end
end
