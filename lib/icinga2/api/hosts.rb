# frozen_string_literal: true

module Icinga2
  module API
    # The host collection, reached through {Client#hosts}.
    #
    # @example
    #   client.hosts.all
    #   client.hosts.find('web01')
    class Hosts

      # @return [Client]
      attr_reader :api_client

      # @param args [Hash]
      # @option args [Client] :api_client
      def initialize(args = {})
        @api_client = args[:api_client]
      end

      # Every host on the server.
      #
      # @return [Array<Host>]
      # @raise [Error] on any transport or HTTP failure
      def all
        objects.all
      end

      # Look a host up by name.
      #
      # Kept on the dedicated `?host=<name>` form rather than {Objects#find}'s
      # `__name` filter: it is the URL this collection has always sent, and the
      # recorded cassettes match on it.
      #
      # @param hostname [String]
      # @return [Host, nil] nil when the host does not exist
      # @raise [Error] on any transport or HTTP failure other than a 404
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
