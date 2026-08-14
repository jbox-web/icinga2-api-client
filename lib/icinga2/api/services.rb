# frozen_string_literal: true

module Icinga2
  module API
    class Services

      attr_reader :api_client, :host

      def initialize(args = {})
        @api_client = args[:api_client]
        @host = args[:host]
      end

      # Icinga only accept double quote in query string
      # https://www.icinga.com/docs/icinga2/latest/doc/12-icinga2-api/#advanced-filters
      def all
        services.all(filter: "match(\"#{Objects.escape(host.name)}\", service.host_name)")
      end

      def find(name)
        all.find { |service| service.name == name }
      end

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
