# frozen_string_literal: true

module Icinga2
  module API
    # A recurring downtime rule.
    #
    # This is configuration, not an active downtime: it is the rule that keeps
    # creating Downtime objects on its schedule. Host#downtimes and
    # Service#downtimes return the latter, never this.
    class ScheduledDowntime < GenericObject

      # The host this rule applies to: the one it was reached from when the
      # chain provided it, resolved from host_name otherwise.
      def host
        @host || memoized(:host) { navigate(:host_name) }
      end

      # The service this rule applies to, or nil when it sits at host level.
      def service
        @service || memoized(:service) { resolve_service }
      end

    end
  end
end
