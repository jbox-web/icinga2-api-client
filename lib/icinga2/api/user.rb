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

      def time_period
        navigate(:period)
      end

    end
  end
end
