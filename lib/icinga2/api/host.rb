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
        host_level_objects(:downtime, force_post: true)
      end

      def comments
        host_level_objects(:comment, force_post: true)
      end

      # Host-level notification rules. Service notifications are reached
      # through #services, same split as #downtimes and #comments.
      def notifications
        host_level_objects(:notification)
      end

      # Host-level recurring downtime rules. These are configuration; the
      # downtimes they create are what #downtimes returns.
      def scheduled_downtimes
        host_level_objects(:scheduled_downtime)
      end

      # The dependencies this host is the child of, i.e. what it needs to be up.
      def dependencies
        collection = scoped_collection(:dependency)
        variable   = collection.type.filter_variable
        escaped    = Objects.escape(name)

        collection.all(filter: %(#{variable}.child_host_name=="#{escaped}"&&#{variable}.child_service_name==""))
      end

      # The groups this host belongs to, as objects. #groups keeps returning
      # the raw names the API sent.
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
