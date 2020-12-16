# frozen_string_literal: true

module Icinga2
  module API
    class Host < Icinga2::API::Resource

      def to_s
        name
      end

      def services
        @services ||= Icinga2::API::Services.new(api_client: api_client, host: self)
      end

    end
  end
end
