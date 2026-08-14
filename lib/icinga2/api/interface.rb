# frozen_string_literal: true

module Icinga2
  module API
    # Transport layer: owns the Faraday connection to an Icinga2 API and turns
    # its answers into plain Ruby, its failures into this gem's own errors.
    #
    # Callers normally reach it through {Client#api} rather than building one.
    #
    # @example
    #   api = Icinga2::API::Interface.new(
    #     base_url: 'https://icinga.example.net:5665',
    #     username: 'root', password: ENV.fetch('ICINGA_API_PASSWORD')
    #   )
    #   api.get('/objects/hosts', query: { attrs: %w[__name state] })
    class Interface

      # Maps Faraday transport errors to this gem's error hierarchy.
      # Order matters: most specific errors must come first (e.g.
      # Faraday::TimeoutError < Faraday::ServerError and
      # Faraday::ResourceNotFound < Faraday::ClientError).
      #
      # @return [Hash{Class => Class}]
      FARADAY_ERRORS = {
        Faraday::TimeoutError     => Error::Timeout,
        Faraday::ConnectionFailed => Error::ConnectionFailed,
        Faraday::ResourceNotFound => Error::NotFound,
        Faraday::ClientError      => Error::ClientError,
        Faraday::ServerError      => Error::ServerError
      }.freeze

      # Every option {#initialize} accepts. Anything else is rejected rather
      # than ignored, so a typo surfaces at build time instead of silently
      # falling back to a default.
      #
      # @return [Array<Symbol>]
      KNOWN_OPTIONS = %i[base_url username password version ssl_options open_timeout timeout logging].freeze

      # @return [String] the API root, e.g. "https://icinga.example.net:5665"
      attr_accessor :base_url

      # @return [String] the API user
      attr_accessor :username

      # @return [String] the API user's password
      attr_accessor :password

      # @return [String] the API version segment, "v1" by default
      attr_accessor :version

      # @return [Hash] Faraday SSL options, e.g. `{ verify: false }`
      attr_accessor :ssl_options

      # @return [Integer, nil] seconds allowed to open the connection
      attr_accessor :open_timeout

      # @return [Integer, nil] seconds allowed for the whole request
      attr_accessor :timeout

      # @return [Hash] logging setup: `:enabled`, `:logger`, `:options`
      attr_accessor :logging

      # @param args [Hash] see {KNOWN_OPTIONS}
      # @option args [String] :base_url required
      # @option args [String] :username required
      # @option args [String] :password required
      # @option args [String] :version ("v1")
      # @option args [Hash] :ssl_options ({})
      # @option args [Integer, nil] :open_timeout (nil)
      # @option args [Integer, nil] :timeout (30)
      # @option args [Hash] :logging ({})
      # @raise [ArgumentError] on an unknown option, or a missing required one
      def initialize(args = {})
        unknown = args.keys - KNOWN_OPTIONS
        raise ArgumentError, "unknown options: #{unknown.join(', ')}" unless unknown.empty?

        @base_url     = args.fetch(:base_url)
        @username     = args.fetch(:username)
        @password     = args.fetch(:password)
        @version      = args.fetch(:version, 'v1')
        @ssl_options  = args.fetch(:ssl_options, {})
        @open_timeout = args.fetch(:open_timeout, nil)
        @timeout      = args.fetch(:timeout, 30)
        @logging      = args.fetch(:logging, {})
      end

      # @return [Logger, nil] the logger to hand to Faraday, if any
      def logger
        logging.fetch(:logger, nil)
      end

      # @return [Hash] options passed to Faraday's logger middleware
      def logger_options
        logging.fetch(:options, {})
      end

      # @return [Boolean] whether request logging is wired in at all
      def enable_logs
        logging.fetch(:enabled, false)
      end

      # Send a GET and unwrap the Icinga2 envelope.
      #
      # @param path [String] path below the version segment, e.g. "/objects/hosts"
      # @param query [Hash] query parameters; an Array value is serialised as a
      #   repeated key (`attrs=a&attrs=b`), the only form Icinga2 honours
      # @return [Array<Hash>] the `results` array, `[]` on an empty or
      #   malformed body
      # @raise [Error] on any transport or HTTP failure, never a Faraday error
      def get(path, query: {})
        # Prepare request options
        url = build_url(path, query)

        # Send request
        with_error_handling { results(client.get(url)) }
      end

      # Send a POST and unwrap the Icinga2 envelope.
      #
      # Also the way to issue a GET whose filter is too large for a query
      # string: pass `headers: { 'X-HTTP-Method-Override' => 'GET' }`.
      #
      # @param path [String] path below the version segment
      # @param query [Hash] query parameters
      # @param params [Hash] request body, serialised as JSON
      # @param headers [Hash] extra request headers
      # @return [Array<Hash>] the `results` array, `[]` on an empty or
      #   malformed body
      # @raise [Error] on any transport or HTTP failure
      def post(path, query: {}, params: {}, headers: {})
        # Prepare request options
        url     = build_url(path, query)
        headers = headers.merge(accept: 'application/json')

        with_error_handling { results(client.post(url, params.to_json, headers)) }
      end

      # Subscribe to the Icinga2 event stream (/v1/events). Blocks, yielding each
      # newline-delimited JSON event as a Hash until the connection is closed.
      #
      # Uses a connection of its own, without the JSON response middleware and
      # without a read timeout: the stream never completes on its own.
      #
      # @param path [String] usually "/events"
      # @param params [Hash] request body: `:types`, `:queue`, optional `:filter`
      # @yieldparam event [Hash] one decoded event
      # @return [nil] only once the connection closes
      # @raise [Error] on any transport or HTTP failure
      def stream(path, params: {}, &block)
        buffer = +''

        with_error_handling do
          streaming_client.post(build_url(path), params.to_json, accept: 'application/json') do |req|
            req.options.on_data = proc { |chunk, _received| emit_events(buffer << chunk, &block) }
          end
        end

        nil
      end

      private

      # Yield and remove every complete newline-delimited JSON event in +buffer+.
      def emit_events(buffer)
        while (newline = buffer.index("\n"))
          line = buffer.slice!(0, newline + 1).chomp
          yield JSON.parse(line) unless line.empty?
        end
      end

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
        url    = "#{base_url}/#{version}#{path}"
        params = encode_query(query)
        url += "?#{params}" unless params.empty?
        url
      end

      # Icinga2 expects multi-valued parameters as a repeated key
      # (attrs=a&attrs=b) and silently ignores the bracketed form
      # (attrs[]=a&attrs[]=b) that ActiveSupport's #to_query emits: the request
      # succeeds and every attribute comes back, so the caller cannot tell the
      # restriction was dropped. Array values are therefore expanded by hand.
      def encode_query(query)
        query.flat_map do |key, value|
          Array(value).map { |item| "#{CGI.escape(key.to_s)}=#{CGI.escape(item.to_s)}" }
        end.join('&')
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

      # A connection without the JSON response middleware or read timeout:
      # the event stream is parsed line by line and stays open indefinitely.
      def streaming_client
        @streaming_client ||= Faraday.new(base_url, ssl: ssl_options) do |builder|
          builder.request :authorization, :basic, username, password
          builder.response :raise_error
        end
      end

    end
  end
end
