# frozen_string_literal: true

module Icinga2
  module API
    class Interface

      # Maps Faraday transport errors to this gem's error hierarchy.
      # Order matters: most specific errors must come first (e.g.
      # Faraday::TimeoutError < Faraday::ServerError and
      # Faraday::ResourceNotFound < Faraday::ClientError).
      FARADAY_ERRORS = {
        Faraday::TimeoutError     => Error::Timeout,
        Faraday::ConnectionFailed => Error::ConnectionFailed,
        Faraday::ResourceNotFound => Error::NotFound,
        Faraday::ClientError      => Error::ClientError,
        Faraday::ServerError      => Error::ServerError
      }.freeze

      KNOWN_OPTIONS = %i[base_url username password version ssl_options open_timeout timeout logging].freeze

      attr_accessor :base_url, :username, :password, :version, :ssl_options, :open_timeout, :timeout, :logging

      def initialize(args = {})
        unknown = args.keys - KNOWN_OPTIONS
        raise ArgumentError, "unknown options: #{unknown.join(', ')}" unless unknown.empty?

        @base_url     = args.fetch(:base_url)
        @username     = args.fetch(:username)
        @password     = args.fetch(:password)
        @version      = args.fetch(:version, 'v1')
        @ssl_options  = args.fetch(:ssl_options, {})
        @open_timeout = args.fetch(:open_timeout, nil)
        @timeout      = args.fetch(:timeout, nil)
        @logging      = args.fetch(:logging, {})
      end

      def logger
        logging.fetch(:logger, nil)
      end

      def logger_options
        logging.fetch(:options, {})
      end

      def enable_logs
        logging.fetch(:enabled, false)
      end

      def get(path, query: {})
        # Prepare request options
        url = build_url(path, query)

        # Send request
        with_error_handling { results(client.get(url)) }
      end

      def post(path, query: {}, params: {}, headers: {})
        # Prepare request options
        url     = build_url(path, query)
        headers = headers.merge(accept: 'application/json')

        with_error_handling { results(client.post(url, params.to_json, headers)) }
      end

      private

      # Unwrap the Icinga2 envelope, tolerating empty or malformed bodies
      # (e.g. a 200 response whose body has no "results" key).
      def results(response)
        body = response.body
        body.is_a?(Hash) ? Array(body['results']) : []
      end

      # Translate Faraday transport errors into the gem's own error hierarchy
      # so callers never have to rescue Faraday-specific exceptions.
      def with_error_handling
        yield
      rescue Faraday::Error => e
        _, error_class = FARADAY_ERRORS.find { |faraday_error, _| e.is_a?(faraday_error) }
        raise (error_class || Error).new(e.message, response: e.response)
      end

      def build_url(path, query = {})
        url = "#{base_url}/#{version}#{path}"
        unless query.empty?
          params = query.to_query
          url += "?#{params}"
        end
        url
      end

      def client
        request_options = { open_timeout: open_timeout, timeout: timeout }.compact

        @client ||= Faraday.new(base_url, ssl: ssl_options, request: request_options) do |builder|
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
