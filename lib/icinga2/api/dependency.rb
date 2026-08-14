# frozen_string_literal: true

module Icinga2
  module API
    # A dependency between two checkables: while the parent is down, the child
    # stops being checked and notified about.
    class Dependency < GenericObject

      # The host the child depends on.
      #
      # @return [Host, nil]
      # @raise [Error] on any transport or HTTP failure
      def parent_host
        navigate(:parent_host_name)
      end

      # The host whose checks the dependency guards.
      #
      # @return [Host, nil]
      # @raise [Error] on any transport or HTTP failure
      def child_host
        navigate(:child_host_name)
      end

      # The service the child depends on.
      #
      # Wired by hand: Icinga2 declares no reference on any `service_name`
      # field, so this arc cannot be derived from the catalog.
      #
      # @return [Service, nil] nil when the parent side sits at host level
      # @raise [Error] on any transport or HTTP failure
      def parent_service
        resolve_service(host_field: :parent_host_name, service_field: :parent_service_name)
      end

      # The service the dependency guards.
      #
      # @return [Service, nil] nil when the child side sits at host level
      # @raise [Error] on any transport or HTTP failure
      def child_service
        resolve_service(host_field: :child_host_name, service_field: :child_service_name)
      end

      # The period during which the dependency applies.
      #
      # @return [TimePeriod, nil]
      # @raise [Error] on any transport or HTTP failure
      def time_period
        navigate(:period)
      end

    end
  end
end
