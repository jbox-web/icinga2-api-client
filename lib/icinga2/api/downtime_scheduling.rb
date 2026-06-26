# frozen_string_literal: true

module Icinga2
  module API
    # Shared downtime-scheduling behaviour for Host and Service.
    module DowntimeScheduling

      # Parameters Icinga2 requires to schedule a downtime.
      REQUIRED_PARAMS = %i[author comment start_time end_time duration].freeze

      private

      def validate_downtime_params!(opts)
        missing = REQUIRED_PARAMS - opts.keys
        return if missing.empty?

        raise ArgumentError, "missing downtime parameters: #{missing.join(', ')}"
      end

      # Build a Downtime from the schedule-downtime action response.
      def build_scheduled_downtime(results, host:, service: nil)
        result = results.first
        raise Error, 'downtime was not scheduled' unless result

        Downtime.new('__name' => result['name'], api_client: api_client, host: host, service: service)
      end

    end
  end
end
