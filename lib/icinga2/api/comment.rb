# frozen_string_literal: true

module Icinga2
  module API
    class Comment < Icinga2::API::Resource

      attr_reader :service, :host

      def initialize(args = {})
        @service = args.delete(:service)
        @host    = args.delete(:host)

        super
      end

      def full_name
        __name
      end

      alias to_s full_name

      def remove
        result = api_client.api.post('/actions/remove-comment', query: { comment: full_name })
        raise Error, "comment '#{full_name}' was not removed" if result.empty?

        result.first
      end

    end
  end
end
