# frozen_string_literal: true

module Icinga2
  module API
    class Hosts

      attr_reader :api_client

      def initialize(args = {})
        @api_client = args[:api_client]
      end

      def all
        objects.all
      end

      # Kept on the dedicated ?host=<name> form rather than Objects#find's
      # __name filter: it is the URL this collection has always sent, and the
      # recorded cassettes match on it.
      def find(hostname)
        begin
          hosts = api_client.api.get('/objects/hosts', query: { host: hostname })
        rescue Icinga2::API::Error::NotFound => _e
          nil
        else
          host = hosts.first
          build_host(host['attrs']) if host
        end
      end

      private

      def objects
        @objects ||= Objects.new(api_client: api_client, type: :host)
      end

      def build_host(attrs)
        Host.new attrs.merge(api_client: api_client)
      end

    end
  end
end
