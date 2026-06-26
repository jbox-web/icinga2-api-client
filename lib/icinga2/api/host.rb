# frozen_string_literal: true

module Icinga2
  module API
    class Host < Icinga2::API::Resource

      include Icinga2::API::Actions

      def to_s
        name
      end

      def services
        @services ||= Icinga2::API::Services.new(api_client: api_client, host: self)
      end

      def downtimes
        fetch_downtimes.collect do |downtime_attributes|
          Downtime.new downtime_attributes['attrs'].merge(api_client: api_client, host: self)
        end
      end

      def comments
        fetch_comments.collect do |comment_attributes|
          Comment.new comment_attributes['attrs'].merge(api_client: api_client, host: self)
        end
      end

      private

      def action_type
        'Host'
      end

      def action_filter
        "host.name==\"#{name}\""
      end

      def build_scheduled_downtime(name)
        Downtime.new('__name' => name, api_client: api_client, host: self)
      end

      def build_comment(name)
        Comment.new('__name' => name, api_client: api_client, host: self)
      end

      def fetch_downtimes
        fetch_objects('/objects/downtimes', 'downtime')
      end

      def fetch_comments
        fetch_objects('/objects/comments', 'comment')
      end

      # Host-level objects only: filter out those attached to a service.
      def fetch_objects(path, kind)
        filter  = "#{kind}.host_name==\"#{name}\" && #{kind}.service_name==\"\""
        headers = { 'X-HTTP-Method-Override' => 'GET' }
        api_client.api.post(path, params: { filter: filter }, headers: headers)
      end

    end
  end
end
