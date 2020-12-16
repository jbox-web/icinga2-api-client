# frozen_string_literal: true

module Icinga2
  module API
    class Service < Icinga2::API::Resource

      attr_reader :host

      def initialize(args = {})
        @host = args.delete(:host)
        super(args)
      end

      def full_name
        __name
      end

      alias to_s full_name

      def schedule_downtime(opts = {})
        opts = opts.merge(filter: "service.name==\"#{name}\" && service.host_name==\"#{host.name}\"")
        api_client.api.post('/actions/schedule-downtime', query: { type: 'Service' }, params: opts)
      end

      def downtimes
        @downtimes ||= fetch_downtimes.collect do |downtime_attributes|
          build_downtime(downtime_attributes['attrs'])
        end
      end

      private

      def fetch_downtimes
        opts    = { filter: "service.name==\"#{name}\" && service.host_name==\"#{host.name}\"" }
        headers = { 'X-HTTP-Method-Override' => 'GET' }
        api_client.api.post('/objects/downtimes', params: opts, headers: headers)
      end

      def build_downtime(attrs)
        Downtime.new attrs.merge(api_client: api_client, host: host, service: self)
      end

    end
  end
end
