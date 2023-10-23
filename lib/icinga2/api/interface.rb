# frozen_string_literal: true

module Icinga2
  module API
    class Interface

      attr_accessor :base_url, :username, :password, :version, :ssl_options, :logging, :logger, :logger_options, :enable_logs

      def initialize(args = {})
        @base_url       = args.fetch(:base_url)
        @username       = args.fetch(:username)
        @password       = args.fetch(:password)
        @version        = args.fetch(:version, 'v1')
        @ssl_options    = args.fetch(:ssl_options, {})
        @logging        = args.fetch(:logging, {})
        @logger         = logging.fetch(:logger, nil)
        @logger_options = logging.fetch(:options, {})
        @enable_logs    = logging.fetch(:enabled, false)
      end

      def get(path, query: {})
        # Prepare request options
        url = build_url(path, query)

        # Send request
        client.get(url).body['results']
      end

      def post(path, query: {}, params: {}, headers: {})
        # Prepare request options
        url     = build_url(path, query)
        headers = headers.merge(accept: 'application/json')

        client.post(url, params.to_json, headers).body['results']
      end

      private

      def build_url(path, query = {})
        url = "#{base_url}/#{version}#{path}"
        unless query.empty?
          params = query.to_query
          url += "?#{params}"
        end
        url
      end

      def client
        @client ||= Faraday.new(base_url, ssl: ssl_options) do |builder|
          builder.request :authorization, :basic, username, password
          builder.request :json
          builder.response :raise_error
          builder.response :json
          builder.response :logger, logger, logger_options if enable_logs
        end
      end

    end
  end
end
