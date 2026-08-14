# frozen_string_literal: true

module Icinga2
  module API
    # The entry point: one client per Icinga2 endpoint, from which every
    # collection and every object is reached.
    #
    # A client is **not** safe to share across threads or fibers concurrently.
    # Use one per thread, or guard it with your own mutex.
    #
    # @example
    #   client = Icinga2::API::Client.new(
    #     'https://icinga.example.net:5665',
    #     username: 'root', password: ENV.fetch('ICINGA_API_PASSWORD')
    #   )
    #   client.hosts.find('web01').services.find('ssh').downtimes
    #   client.notifications.all(filter: 'notification.host_name=="web01"')
    class Client

      # @return [String] the API root this client talks to
      attr_reader :base_url

      # @return [Hash] the options handed to {Interface}
      attr_reader :options

      # @return [Hash{String => Objects}] collections memoized per type name
      private attr_reader :collections

      # @param base_url [String] API root, e.g. "https://icinga.example.net:5665"
      # @param options [Hash] passed on to {Interface#initialize} — `:username`
      #   and `:password` are required there, the rest is optional
      def initialize(base_url, options = {})
        @base_url    = base_url
        @options     = options
        @api         = nil
        @hosts       = nil
        @collections = {}
      end

      # The transport, built on first use from {#base_url} and {#options}.
      #
      # @return [Interface]
      def api
        @api ||= Icinga2::API::Interface.new(options.merge(base_url: base_url))
      end

      # @return [Hosts] the host collection
      def hosts
        @hosts ||= Icinga2::API::Hosts.new(api_client: self)
      end

      # A collection over any type carried by the catalog. The named readers
      # below cover the types the gem models; this is the way in for anything
      # the catalog gains later.
      #
      # @example
      #   client.objects(:notification).all(filter: '...', attrs: %w[__name])
      #
      # @param type [Symbol, String] Icinga name ("ScheduledDowntime") or
      #   snake_case symbol (`:scheduled_downtime`)
      # @return [Objects] memoized per type
      # @raise [Error::UnknownType] if the catalog does not carry that type;
      #   raised locally, before any request
      def objects(type)
        collections[TypeCatalog.default.fetch(type).name] ||=
          Icinga2::API::Objects.new(api_client: self, type: type)
      end

      # Notification rules. Beware the volume: a mid-sized master carries tens
      # of thousands, so pass `filter:` and `attrs:`.
      #
      # @return [Objects] a collection of {Notification}
      def notifications
        objects(:notification)
      end

      # @return [Objects] a collection of {User}
      def users
        objects(:user)
      end

      # @return [Objects] a collection of {UserGroup}
      def user_groups
        objects(:user_group)
      end

      # @return [Objects] a collection of {TimePeriod}
      def time_periods
        objects(:time_period)
      end

      # @return [Objects] a collection of {HostGroup}
      def host_groups
        objects(:host_group)
      end

      # @return [Objects] a collection of {ServiceGroup}
      def service_groups
        objects(:service_group)
      end

      # @return [Objects] a collection of {Dependency}
      def dependencies
        objects(:dependency)
      end

      # Recurring downtime rules — configuration, not the downtimes they
      # create. For those, see {Host#downtimes} and {Service#downtimes}.
      #
      # @return [Objects] a collection of {ScheduledDowntime}
      def scheduled_downtimes
        objects(:scheduled_downtime)
      end

      # The daemon's status components, as the API returns them.
      #
      # @return [Array<Hash>]
      # @raise [Error] on any transport or HTTP failure
      def status
        api.get('/status')
      end

      # Subscribe to the Icinga2 event stream. **Blocks** until the connection
      # is closed, yielding each event; break out of the block to stop.
      #
      # @example
      #   client.subscribe(types: %w[CheckResult StateChange], queue: 'mine') do |event|
      #     puts event['type']
      #   end
      #
      # @param types [String, Array<String>] event types to subscribe to
      # @param queue [String] queue name; Icinga2 dedupes subscribers by it
      # @param filter [String, nil] optional Icinga filter
      # @yieldparam event [Hash] one decoded event
      # @return [nil] only once the connection closes
      # @raise [Error] on any transport or HTTP failure
      def subscribe(types:, queue:, filter: nil, &block)
        params = { types: Array(types), queue: queue }
        params[:filter] = filter if filter
        api.stream('/events', params: params, &block)
      end
    end
  end
end
