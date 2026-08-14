# frozen_string_literal: true

module Icinga2
  module API
    # A monitored host, reached through {Client#hosts}.
    #
    # Carries the object actions of {Actions} and the collections hanging off
    # it. Everything named `#downtimes`, `#comments`, `#notifications` or
    # `#scheduled_downtimes` here is **host-level only**: what is attached to a
    # service is reached through {#services}.
    #
    # @example
    #   host = client.hosts.find('web01')
    #   host.services.find('ssh').downtimes
    #   host.notifications
    class Host < Icinga2::API::Resource

      include Icinga2::API::Actions

      # @return [String] the host name
      def to_s
        name
      end

      # @return [Services] this host's service collection
      def services
        @services ||= Icinga2::API::Services.new(api_client: api_client, host: self)
      end

      # Downtimes currently in effect on the host itself.
      #
      # @return [Array<Downtime>]
      # @raise [Error] on any transport or HTTP failure
      def downtimes
        host_level_objects(:downtime, force_post: true)
      end

      # Comments attached to the host itself.
      #
      # @return [Array<Comment>]
      # @raise [Error] on any transport or HTTP failure
      def comments
        host_level_objects(:comment, force_post: true)
      end

      # Host-level notification rules. Service notifications are reached
      # through {#services}, same split as {#downtimes} and {#comments}.
      #
      # @return [Array<Notification>]
      # @raise [Error] on any transport or HTTP failure
      def notifications
        host_level_objects(:notification)
      end

      # Host-level recurring downtime rules. These are configuration; the
      # downtimes they create are what {#downtimes} returns.
      #
      # @return [Array<ScheduledDowntime>]
      # @raise [Error] on any transport or HTTP failure
      def scheduled_downtimes
        host_level_objects(:scheduled_downtime)
      end

      # The dependencies this host is the child of, i.e. what it needs to be up.
      #
      # @return [Array<Dependency>]
      # @raise [Error] on any transport or HTTP failure
      def dependencies
        collection = scoped_collection(:dependency)
        variable   = collection.type.filter_variable
        escaped    = Objects.escape(name)

        collection.all(filter: %(#{variable}.child_host_name=="#{escaped}"&&#{variable}.child_service_name==""))
      end

      # The groups this host belongs to, as objects. `#groups` keeps returning
      # the raw names the API sent.
      #
      # @return [Array<HostGroup>] empty when the host has no group, without
      #   sending a request
      # @raise [Error] on any transport or HTTP failure
      def host_groups
        Objects.new(api_client: api_client, type: :host_group).find_many(Array(to_h[:groups]))
      end

      private

      def scoped_collection(type)
        Objects.new(api_client: api_client, type: type, context: { host: self })
      end

      # Host-level objects only: those attached to a service are filtered out.
      #
      # Downtimes and comments pass force_post because that is the request
      # shape this collection has always sent — the single place that decision
      # now lives, instead of one copy per method.
      def host_level_objects(type, force_post: false)
        collection = scoped_collection(type)
        variable   = collection.type.filter_variable
        escaped    = Objects.escape(name)

        collection.all(filter:     %(#{variable}.host_name=="#{escaped}"&&#{variable}.service_name==""),
                       force_post: force_post)
      end

      def action_type
        'Host'
      end

      def action_filter
        "host.name==\"#{Objects.escape(name)}\""
      end

      def build_scheduled_downtime(name)
        Downtime.new('__name' => name, api_client: api_client, host: self)
      end

      def build_comment(name)
        Comment.new('__name' => name, api_client: api_client, host: self)
      end

    end
  end
end
