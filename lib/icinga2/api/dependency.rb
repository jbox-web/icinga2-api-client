# frozen_string_literal: true

module Icinga2
  module API
    # A dependency between two checkables: while the parent is down, the child
    # stops being checked and notified about.
    class Dependency < GenericObject

      def parent_host
        navigate(:parent_host_name)
      end

      def child_host
        navigate(:child_host_name)
      end

      # Both sides can sit at host level, in which case the service is nil.
      def parent_service
        resolve_service(host_field: :parent_host_name, service_field: :parent_service_name)
      end

      def child_service
        resolve_service(host_field: :child_host_name, service_field: :child_service_name)
      end

      def time_period
        navigate(:period)
      end

    end
  end
end
