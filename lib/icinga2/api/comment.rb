# frozen_string_literal: true

module Icinga2
  module API
    # A comment attached to a host or a service, reached through
    # {Host#comments}, {Service#comments} or created by {Actions#add_comment}.
    class Comment < Icinga2::API::Resource

      # @return [Service, nil] nil for a host-level comment
      attr_reader :service

      # @return [Host, nil]
      attr_reader :host

      # @param args [Hash] the comment's attributes, plus `:api_client` and
      #   optionally `:host` / `:service`
      def initialize(args = {})
        @service = args.delete(:service)
        @host    = args.delete(:host)

        super
      end

      # @return [String] the Icinga `__name`
      def full_name
        __name
      end

      # @!method to_s
      #   Alias of {#full_name}.
      #   @return [String]
      alias to_s full_name

      # Delete the comment.
      #
      # @return [Hash] the API's own result entry
      # @raise [Error] if nothing was removed, or on any transport failure
      def remove
        result = api_client.api.post('/actions/remove-comment', query: { comment: full_name })
        raise Error, "comment '#{full_name}' was not removed" if result.empty?

        result.first
      end

    end
  end
end
