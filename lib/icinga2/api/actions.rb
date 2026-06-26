# frozen_string_literal: true

module Icinga2
  module API
    # Object-scoped Icinga2 actions shared by Host and Service.
    #
    # Includers must provide (privately):
    #   - #action_type   => "Host" or "Service"
    #   - #action_filter => the Icinga2 filter selecting this object
    #   - #build_scheduled_downtime(name) => a Downtime for the given name
    #   - #build_comment(name) => a Comment for the given name
    module Actions

      REQUIRED_DOWNTIME_PARAMS = %i[author comment start_time end_time duration].freeze
      AUTHOR_COMMENT_PARAMS    = %i[author comment].freeze

      def schedule_downtime(opts = {})
        require_action_params!(opts, REQUIRED_DOWNTIME_PARAMS)
        results = run_action('schedule-downtime', opts)
        build_scheduled_downtime(results.first['name'])
      end

      def acknowledge(opts = {})
        require_action_params!(opts, AUTHOR_COMMENT_PARAMS)
        run_action('acknowledge-problem', opts).first
      end

      def remove_acknowledgement(opts = {})
        run_action('remove-acknowledgement', opts).first
      end

      def add_comment(opts = {})
        require_action_params!(opts, AUTHOR_COMMENT_PARAMS)
        build_comment(run_action('add-comment', opts).first['name'])
      end

      def send_notification(opts = {})
        require_action_params!(opts, AUTHOR_COMMENT_PARAMS)
        run_action('send-custom-notification', opts).first
      end

      private

      def require_action_params!(opts, required)
        missing = required - opts.keys
        return if missing.empty?

        raise ArgumentError, "missing parameters: #{missing.join(', ')}"
      end

      def run_action(name, opts)
        params  = opts.merge(filter: action_filter)
        results = api_client.api.post("/actions/#{name}", query: { type: action_type }, params: params)
        raise Error, "action '#{name}' affected no object" if results.empty?

        results
      end

    end
  end
end
