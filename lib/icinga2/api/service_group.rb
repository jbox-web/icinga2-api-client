# frozen_string_literal: true

module Icinga2
  module API
    # A group of services.
    class ServiceGroup < GenericObject

      # The services holding this group.
      def services
        members(:service)
      end

      # The groups this group itself belongs to. #groups keeps returning names.
      def parent_groups
        navigate(:groups)
      end

    end
  end
end
