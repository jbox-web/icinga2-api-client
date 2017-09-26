module Icinga2
  module API
    class Hosts

      attr_reader :api_client

      def initialize(args = {})
        @api_client = args[:api_client]
      end

      def all
        hosts = api_client.api.get('/objects/hosts')
        hosts.map { |h| build_host(h['attrs']) }
      end

      def find(hostname)
        begin
          hosts = api_client.api.get('/objects/hosts', query: { host: hostname })
        rescue RestClient::NotFound => _
          nil
        else
          host = hosts.first
          build_host(host['attrs'])
        end
      end

      private

      def build_host(attrs)
        Host.new attrs.merge(api_client: api_client)
      end

    end
  end
end
