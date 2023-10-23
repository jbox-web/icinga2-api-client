# frozen_string_literal: true

module Icinga2
  module API
    class Interface

      attr_accessor :base_url, :username, :password, :version, :verify_ssl

      def initialize(args = {})
        @base_url   = args[:base_url]
        @username   = args[:username]
        @password   = args[:password]
        @version    = args[:version]
        @verify_ssl = args[:verify_ssl]
      end

      def get(path, query: {})
        # Prepare request options
        url  = build_url(path, query)
        opts = request_options(url).merge(method: :get)

        # Send request
        send_request(opts)
      end

      def post(path, query: {}, params: {}, headers: {})
        # Prepare request options
        url     = build_url(path, query)
        headers = headers.merge(content_type: :json, accept: 'application/json')
        opts    = request_options(url).merge(method: :post, headers: headers, payload: params.to_json)

        # Send request
        send_request(opts)
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

      def request_options(url)
        { url: url, user: username, password: password, verify_ssl: verify_ssl }
      end

      def send_request(opts = {})
        data = RestClient::Request.execute(opts)
        data = JSON.parse(data.body)
        data['results']
      end

    end
  end
end
