# frozen_string_literal: true

module Icinga2
  module API
    # A group of hosts.
    class HostGroup < GenericObject

      # The hosts holding this group.
      def hosts
        members(:host)
      end

      # The groups this group itself belongs to. #groups keeps returning names.
      def parent_groups
        navigate(:groups)
      end

    end
  end
end
