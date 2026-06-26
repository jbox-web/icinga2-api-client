# frozen_string_literal: true

module Icinga2
  module API
    class Host < Icinga2::API::Resource

      include Icinga2::API::DowntimeScheduling

      def to_s
        name
      end

      def services
        @services ||= Icinga2::API::Services.new(api_client: api_client, host: self)
      end

      def schedule_downtime(opts = {})
        validate_downtime_params!(opts)

        opts    = opts.merge(filter: "host.name==\"#{name}\"")
        results = api_client.api.post('/actions/schedule-downtime', query: { type: 'Host' }, params: opts)
        build_scheduled_downtime(results, host: self)
      end

      def downtimes
        fetch_downtimes.collect do |downtime_attributes|
          Downtime.new downtime_attributes['attrs'].merge(api_client: api_client, host: self)
        end
      end

      private

      def fetch_downtimes
        opts    = { filter: "downtime.host_name==\"#{name}\" && downtime.service_name==\"\"" }
        headers = { 'X-HTTP-Method-Override' => 'GET' }
        api_client.api.post('/objects/downtimes', params: opts, headers: headers)
      end

    end
  end
end
