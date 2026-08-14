# frozen_string_literal: true

module Icinga2
  module API
    # A notification rule attached to a host or a service.
    #
    # Not to be confused with Actions#send_notification, which fires a one-off
    # custom notification: this object is the configuration deciding who gets
    # told, when, and through which command.
    class Notification < GenericObject

      # The users named directly on the rule. #users keeps returning the raw
      # names the API sent.
      def notified_users
        navigate(:users)
      end

      # The user groups named on the rule. #user_groups keeps returning names.
      def notified_user_groups
        navigate(:user_groups)
      end

      def time_period
        navigate(:period)
      end

      def notification_command
        navigate(:command)
      end

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
