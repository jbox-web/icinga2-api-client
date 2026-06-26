# frozen_string_literal: true

module Icinga2
  module API

    # Base class for every error raised by this gem.
    # Faraday transport errors are translated into these so callers don't
    # need to depend on Faraday's exception hierarchy.
    class Error < StandardError

      # The Faraday response hash ({ status:, headers:, body:, ... }) when the
      # error originates from an HTTP response; nil for connection/timeout errors.
      attr_reader :response

      def initialize(message = nil, response: nil)
        @response = response
        super(message)
      end

      # The connection could not be established (DNS, refused, reset, ...).
      class ConnectionFailed < Error; end

      # The request timed out (open or read timeout).
      class Timeout < Error; end

      # The server answered with a 4xx status.
      class ClientError < Error; end

      # The server answered with a 404 status.
      class NotFound < ClientError; end

      # The server answered with a 5xx status.
      class ServerError < Error; end

    end

  end
end
