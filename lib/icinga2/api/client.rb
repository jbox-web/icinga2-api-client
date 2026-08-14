# frozen_string_literal: true

module Icinga2
  module API
    class Client

      attr_reader :base_url, :options

      private attr_reader :collections

      def initialize(base_url, options = {})
        @base_url    = base_url
        @options     = options
        @api         = nil
        @hosts       = nil
        @collections = {}
      end

      def api
        @api ||= Icinga2::API::Interface.new(options.merge(base_url: base_url))
      end

      def hosts
        @hosts ||= Icinga2::API::Hosts.new(api_client: self)
      end

      # A collection over any type carried by the catalog, e.g.
      #   client.objects(:notification).all(filter: '...', attrs: %w[__name])
      # Named readers below cover the types the gem models; this is the way in
      # for anything the catalog gains later.
      def objects(type)
        collections[TypeCatalog.default.fetch(type).name] ||=
          Icinga2::API::Objects.new(api_client: self, type: type)
      end

      def notifications
        objects(:notification)
      end

      def users
        objects(:user)
      end

      def user_groups
        objects(:user_group)
      end

      def time_periods
        objects(:time_period)
      end

      def host_groups
        objects(:host_group)
      end

      def service_groups
        objects(:service_group)
      end

      def dependencies
        objects(:dependency)
      end

      def scheduled_downtimes
        objects(:scheduled_downtime)
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
