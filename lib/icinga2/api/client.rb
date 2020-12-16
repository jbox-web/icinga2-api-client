# frozen_string_literal: true

module Icinga2
  module API
    class Client

      attr_reader :base_url, :options

      def initialize(base_url, options = {})
        @base_url = base_url
        @options  = options
      end

      def api
        @api ||= Icinga2::API::Interface.new(options.merge(base_url: base_url))
      end

      def hosts
        @hosts ||= Icinga2::API::Hosts.new(api_client: self)
      end
    end
  end
end
