# frozen_string_literal: true

module Icinga2
  module API
    class Downtime < Icinga2::API::Resource

      attr_reader :service, :host

      def initialize(args = {})
        @service = args.delete(:service)
        @host    = args.delete(:host)

        args['start_time'] = Time.at(args['start_time'].to_i) if args.key?('start_time')
        args['end_time']   = Time.at(args['end_time'].to_i) if args.key?('end_time')

        super
      end

      def full_name
        __name
      end

      alias to_s full_name

      def cancel
        result = api_client.api.post('/actions/remove-downtime', query: { downtime: full_name })
        raise Error, "downtime '#{full_name}' was not cancelled" if result.empty?

        result.first
      end

    end
  end
end
