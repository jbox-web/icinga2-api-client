# frozen_string_literal: true

module Icinga2
  module API
    # A notification recipient.
    class User < GenericObject

      # The groups this user belongs to, as objects. #groups keeps returning
      # the raw names the API sent.
      def user_groups
        navigate(:groups)
      end

      # The period during which the user is notified.
      #
      # @return [TimePeriod, nil]
      # @raise [Error] on any transport or HTTP failure
      def time_period
        navigate(:period)
      end

    end
  end
end
