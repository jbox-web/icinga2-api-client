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

      # @return [Array<Symbol>] required by {#schedule_downtime}
      REQUIRED_DOWNTIME_PARAMS     = %i[author comment start_time end_time duration].freeze

      # @return [Array<Symbol>] required by {#acknowledge}, {#add_comment} and
      #   {#send_notification}
      AUTHOR_COMMENT_PARAMS        = %i[author comment].freeze

      # @return [Array<Symbol>] required by {#process_check_result}
      REQUIRED_CHECK_RESULT_PARAMS = %i[exit_status plugin_output].freeze

      # Put the object in downtime.
      #
      # `duration` is mandatory even for a fixed downtime, which is the
      # default. Times are Unix timestamps, so call `#to_i` on them.
      #
      # @example
      #   host.schedule_downtime(
      #     author: 'admin', comment: 'Maintenance',
      #     start_time: Time.now.to_i, end_time: (Time.now + 3600).to_i,
      #     duration: 3600
      #   )
      #
      # @param opts [Hash]
      # @option opts [String] :author required
      # @option opts [String] :comment required
      # @option opts [Integer] :start_time required, Unix timestamp
      # @option opts [Integer] :end_time required, Unix timestamp
      # @option opts [Integer] :duration required, seconds
      # @option opts [Boolean] :fixed (true)
      # @return [Downtime] the downtime created, not the raw payload
      # @raise [ArgumentError] if a required parameter is missing
      # @raise [Error] if the action affected no object, or on any transport
      #   or HTTP failure
      def schedule_downtime(opts = {})
        require_action_params!(opts, REQUIRED_DOWNTIME_PARAMS)
        results = run_action('schedule-downtime', opts)
        build_scheduled_downtime(results.first['name'])
      end

      # Acknowledge the object's current problem.
      #
      # @param opts [Hash]
      # @option opts [String] :author required
      # @option opts [String] :comment required
      # @option opts [Boolean] :sticky
      # @option opts [Boolean] :notify
      # @option opts [Integer] :expiry Unix timestamp
      # @return [Hash] the API's own result entry
      # @raise [ArgumentError] if a required parameter is missing
      # @raise [Error] if the action affected no object
      def acknowledge(opts = {})
        require_action_params!(opts, AUTHOR_COMMENT_PARAMS)
        run_action('acknowledge-problem', opts).first
      end

      # Drop the acknowledgement set by {#acknowledge}.
      #
      # @param opts [Hash]
      # @option opts [String] :author
      # @return [Hash] the API's own result entry
      # @raise [Error] if the action affected no object
      def remove_acknowledgement(opts = {})
        run_action('remove-acknowledgement', opts).first
      end

      # Attach a comment to the object.
      #
      # @param opts [Hash]
      # @option opts [String] :author required
      # @option opts [String] :comment required
      # @return [Comment] the comment created, not the raw payload
      # @raise [ArgumentError] if a required parameter is missing
      # @raise [Error] if the action affected no object
      def add_comment(opts = {})
        require_action_params!(opts, AUTHOR_COMMENT_PARAMS)
        build_comment(run_action('add-comment', opts).first['name'])
      end

      # Fire a one-off custom notification.
      #
      # This is an action, not the {Notification} object: it notifies now,
      # rather than describing who should be notified in general.
      #
      # @param opts [Hash]
      # @option opts [String] :author required
      # @option opts [String] :comment required
      # @option opts [Boolean] :force
      # @return [Hash] the API's own result entry
      # @raise [ArgumentError] if a required parameter is missing
      # @raise [Error] if the action affected no object
      def send_notification(opts = {})
        require_action_params!(opts, AUTHOR_COMMENT_PARAMS)
        run_action('send-custom-notification', opts).first
      end

      # Submit a passive check result.
      #
      # @param opts [Hash]
      # @option opts [Integer] :exit_status required, 0..3
      # @option opts [String] :plugin_output required
      # @option opts [Array, String] :performance_data
      # @option opts [String] :check_source
      # @return [Hash] the API's own result entry
      # @raise [ArgumentError] if a required parameter is missing
      # @raise [Error] if the action affected no object
      def process_check_result(opts = {})
        require_action_params!(opts, REQUIRED_CHECK_RESULT_PARAMS)
        run_action('process-check-result', opts).first
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
