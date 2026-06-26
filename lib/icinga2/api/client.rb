# frozen_string_literal: true

module Icinga2
  module API
    class Client

      attr_reader :base_url, :options

      def initialize(base_url, options = {})
        @base_url = base_url
        @options  = options
      end

      def api
        @api ||= Icinga2::API::Interface.new(options.merge(base_url: base_url))
      end

      def hosts
        @hosts ||= Icinga2::API::Hosts.new(api_client: self)
      end

      def status
        api.get('/status')
      end

      # Subscribe to the Icinga2 event stream. Blocks, yielding each event Hash.
      def subscribe(types:, queue:, filter: nil, &block)
        params = { types: Array(types), queue: queue }
        params[:filter] = filter if filter
        api.stream('/events', params: params, &block)
      end
    end
  end
end
