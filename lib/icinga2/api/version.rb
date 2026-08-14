# frozen_string_literal: true

module Icinga2
  module API

    # The gem version, comparable.
    #
    # @return [Gem::Version]
    def self.gem_version
      Gem::Version.new VERSION::STRING
    end

    # The gem version, in parts. The gemspec reads {STRING}.
    module VERSION

      # @return [Integer]
      MAJOR = 1

      # @return [Integer]
      MINOR = 0

      # @return [Integer]
      TINY  = 0

      # @return [String, nil] pre-release tag, e.g. "rc1"
      PRE   = nil

      # @return [String] e.g. "1.0.0"
      STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')

    end

  end
end
