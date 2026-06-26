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
        fetch_services.collect do |service_attributes|
          build_service(service_attributes['attrs'])
        end
      end

      def find(name)
        all.find { |service| service.name == name }
      end

      def downtimes
        raw = fetch_downtimes
        return [] if raw.empty?

        # Resolve services once instead of per downtime (avoids N+1).
        services_by_name = all.to_h { |service| [service.name, service] }
        raw.collect do |downtime_attributes|
          attrs = downtime_attributes['attrs']
          build_downtime(attrs, services_by_name[attrs['service_name']])
        end
      end

      private

      def fetch_services
        api_client.api.get('/objects/services', query: { filter: "match(\"#{host.name}\", service.host_name)" })
      end

      def fetch_downtimes
        opts    = { filter: "service.host_name==\"#{host.name}\"" }
        headers = { 'X-HTTP-Method-Override' => 'GET' }
        api_client.api.post('/objects/downtimes', params: opts, headers: headers)
      end

      def build_service(attrs)
        Service.new attrs.merge(api_client: api_client, host: host)
      end

      def build_downtime(attrs, service)
        Downtime.new attrs.merge(api_client: api_client, host: host, service: service)
      end

    end
  end
end
