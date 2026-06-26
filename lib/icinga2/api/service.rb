# frozen_string_literal: true

module Icinga2
  module API
    class Service < Icinga2::API::Resource

      include Icinga2::API::Actions

      attr_reader :host

      def initialize(args = {})
        @host = args.delete(:host)
        super
      end

      def full_name
        __name
      end

      alias to_s full_name

      def downtimes
        fetch_downtimes.collect do |downtime_attributes|
          build_downtime(downtime_attributes['attrs'])
        end
      end

      def comments
        fetch_comments.collect do |comment_attributes|
          Comment.new comment_attributes['attrs'].merge(api_client: api_client, host: host, service: self)
        end
      end

      private

      def action_type
        'Service'
      end

      def action_filter
        "service.name==\"#{name}\" && service.host_name==\"#{host.name}\""
      end

      def build_scheduled_downtime(name)
        Downtime.new('__name' => name, api_client: api_client, host: host, service: self)
      end

      def build_comment(name)
        Comment.new('__name' => name, api_client: api_client, host: host, service: self)
      end

      def fetch_downtimes
        fetch_objects('/objects/downtimes')
      end

      def fetch_comments
        fetch_objects('/objects/comments')
      end

      def fetch_objects(path)
        headers = { 'X-HTTP-Method-Override' => 'GET' }
        api_client.api.post(path, params: { filter: action_filter }, headers: headers)
      end

      def build_downtime(attrs)
        Downtime.new attrs.merge(api_client: api_client, host: host, service: self)
      end

    end
  end
end
