# frozen_string_literal: true

module Icinga2
  module API
    # The services of one host, reached through {Host#services}.
    #
    # @example
    #   client.hosts.find('web01').services.find('ssh')
    class Services

      # @return [Client]
      attr_reader :api_client

      # @return [Host] the host these services belong to
      attr_reader :host

      # @param args [Hash]
      # @option args [Client] :api_client
      # @option args [Host] :host
      def initialize(args = {})
        @api_client = args[:api_client]
        @host = args[:host]
      end

      # Every service of {#host}.
      #
      # Icinga only accept double quote in query string
      # https://www.icinga.com/docs/icinga2/latest/doc/12-icinga2-api/#advanced-filters
      #
      # @return [Array<Service>]
      # @raise [Error] on any transport or HTTP failure
      def all
        services.all(filter: "match(\"#{Objects.escape(host.name)}\", service.host_name)")
      end

      # Look one of them up by name. Filtered client-side, over {#all}.
      #
      # @param name [String] the short name, e.g. "ssh", not "web01!ssh"
      # @return [Service, nil]
      # @raise [Error] on any transport or HTTP failure
      def find(name)
        all.find { |service| service.name == name }
      end

      # The downtimes of every service of {#host}, each tied back to the
      # service it belongs to.
      #
      # @return [Array<Downtime>]
      # @raise [Error] on any transport or HTTP failure
      def downtimes
        services_by_name = nil

        # Resolved once, and only if a downtime came back at all: the lookup is
        # a request of its own (avoids both the N+1 and a pointless call).
        filter = "service.host_name==\"#{Objects.escape(host.name)}\""

        downtimes_collection.all(filter: filter, force_post: true) do |attrs|
          services_by_name ||= all.to_h { |service| [service.name, service] }
          build_downtime(attrs, services_by_name[attrs['service_name']])
        end
      end

      private

      def services
        @services ||= Objects.new(api_client: api_client, type: :service, context: { host: host })
      end

      def downtimes_collection
        @downtimes_collection ||= Objects.new(api_client: api_client, type: :downtime, context: { host: host })
      end

      def build_downtime(attrs, service)
        Downtime.new attrs.merge(api_client: api_client, host: host, service: service)
      end

    end
  end
end
