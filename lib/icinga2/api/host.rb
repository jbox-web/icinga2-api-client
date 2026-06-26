# frozen_string_literal: true

module Icinga2
  module API
    class Host < Icinga2::API::Resource

      include Icinga2::API::Actions

      def to_s
        name
      end

      def services
        @services ||= Icinga2::API::Services.new(api_client: api_client, host: self)
      end

      def downtimes
        fetch_downtimes.collect do |downtime_attributes|
          Downtime.new downtime_attributes['attrs'].merge(api_client: api_client, host: self)
        end
      end

      private

      def action_type
        'Host'
      end

      def action_filter
        "host.name==\"#{name}\""
      end

      def build_scheduled_downtime(name)
        Downtime.new('__name' => name, api_client: api_client, host: self)
      end

      def fetch_downtimes
        opts    = { filter: "downtime.host_name==\"#{name}\" && downtime.service_name==\"\"" }
        headers = { 'X-HTTP-Method-Override' => 'GET' }
        api_client.api.post('/objects/downtimes', params: opts, headers: headers)
      end

    end
  end
end
