# frozen_string_literal: true

module Icinga2
  module API
    # A group of notification recipients.
    class UserGroup < GenericObject

      # The users holding this group.
      def users
        members(:user)
      end

      # The groups this group itself belongs to. #groups keeps returning names.
      def parent_groups
        navigate(:groups)
      end

    end
  end
end
