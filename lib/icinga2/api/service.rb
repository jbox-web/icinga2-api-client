# frozen_string_literal: true

module Icinga2
  module API
    # A service monitored on a host, reached through {Host#services}.
    #
    # @example
    #   service = client.hosts.find('web01').services.find('ssh')
    #   service.acknowledge(author: 'admin', comment: 'looking into it')
    class Service < Icinga2::API::Resource

      include Icinga2::API::Actions

      # @return [Host] the host this service runs on
      attr_reader :host

      # @param args [Hash] the service's attributes, plus `:api_client` and
      #   `:host`
      def initialize(args = {})
        @host = args.delete(:host)
        super
      end

      # @return [String] the Icinga `__name`, e.g. "web01!ssh"
      def full_name
        __name
      end

      # @!method to_s
      #   Alias of {#full_name}.
      #   @return [String]
      alias to_s full_name

      # Downtimes currently in effect on this service.
      #
      # @return [Array<Downtime>]
      # @raise [Error] on any transport or HTTP failure
      def downtimes
        scoped_objects(:downtime)
      end

      # Comments attached to this service.
      #
      # @return [Array<Comment>]
      # @raise [Error] on any transport or HTTP failure
      def comments
        scoped_objects(:comment)
      end

      # The notification rules attached to this service.
      #
      # @return [Array<Notification>]
      # @raise [Error] on any transport or HTTP failure
      def notifications
        service_level_objects(:notification)
      end

      # The recurring downtime rules targeting this service.
      #
      # @return [Array<ScheduledDowntime>]
      # @raise [Error] on any transport or HTTP failure
      def scheduled_downtimes
        service_level_objects(:scheduled_downtime)
      end

      # The groups this service belongs to, as objects. `#groups` keeps
      # returning the raw names the API sent.
      #
      # @return [Array<ServiceGroup>]
      # @raise [Error] on any transport or HTTP failure
      def service_groups
        Objects.new(api_client: api_client, type: :service_group).find_many(Array(to_h[:groups]))
      end

      private

      def service_level_objects(type)
        collection = Objects.new(api_client: api_client, type: type, context: { host: host, service: self })
        variable   = collection.type.filter_variable
        escaped    = [Objects.escape(host.name), Objects.escape(name)]

        collection.all(filter: %(#{variable}.host_name=="#{escaped.first}"&&#{variable}.service_name=="#{escaped.last}"))
      end

      def action_type
        'Service'
      end

      def action_filter
        "service.name==\"#{Objects.escape(name)}\" && service.host_name==\"#{Objects.escape(host.name)}\""
      end

      def build_scheduled_downtime(name)
        Downtime.new('__name' => name, api_client: api_client, host: host, service: self)
      end

      def build_comment(name)
        Comment.new('__name' => name, api_client: api_client, host: host, service: self)
      end

      # Downtimes and comments of this service.
      #
      # Filtered through #action_filter, i.e. on the service's own variables
      # rather than on downtime.host_name / downtime.service_name: that is the
      # filter this collection has always sent, and the recorded cassettes
      # match on method and URI only, so a rewrite here would go unnoticed by
      # the suite. Posted for the same reason.
      def scoped_objects(type)
        Objects.new(api_client: api_client, type: type, context: { host: host, service: self })
               .all(filter: action_filter, force_post: true)
      end

    end
  end
end
