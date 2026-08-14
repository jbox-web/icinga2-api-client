# frozen_string_literal: true

module Icinga2
  module API
    # A time period, as referenced by notifications, dependencies and users.
    class TimePeriod < GenericObject

      # Periods folded into this one. #includes keeps returning names.
      def included_periods
        navigate(:includes)
      end

      # Periods carved out of this one. #excludes keeps returning names.
      def excluded_periods
        navigate(:excludes)
      end

    end
  end
end
