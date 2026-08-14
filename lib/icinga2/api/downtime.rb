# frozen_string_literal: true

module Icinga2
  module API
    # A downtime currently in effect, reached through {Host#downtimes} or
    # {Service#downtimes}.
    #
    # Not to be confused with {ScheduledDowntime}, the recurring *rule* that
    # keeps creating these.
    #
    # `start_time` and `end_time` are converted from the epoch integers the API
    # sends into `Time` objects; on input the API expects integers, so callers
    # pass `.to_i`.
    class Downtime < Icinga2::API::Resource

      # @return [Service, nil] nil for a host-level downtime
      attr_reader :service

      # @return [Host, nil]
      attr_reader :host

      # @param args [Hash] the downtime's attributes, plus `:api_client` and
      #   optionally `:host` / `:service`
      def initialize(args = {})
        @service = args.delete(:service)
        @host    = args.delete(:host)

        args['start_time'] = Time.at(args['start_time'].to_i) if args.key?('start_time')
        args['end_time']   = Time.at(args['end_time'].to_i) if args.key?('end_time')

        super
      end

      # @return [String] the Icinga `__name`
      def full_name
        __name
      end

      # @!method to_s
      #   Alias of {#full_name}.
      #   @return [String]
      alias to_s full_name

      # Cancel the downtime.
      #
      # @return [Hash] the API's own result entry
      # @raise [Error] if nothing was cancelled, or on any transport failure
      def cancel
        result = api_client.api.post('/actions/remove-downtime', query: { downtime: full_name })
        raise Error, "downtime '#{full_name}' was not cancelled" if result.empty?

        result.first
      end

    end
  end
end
