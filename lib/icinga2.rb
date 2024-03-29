# frozen_string_literal: true

require 'json'
require 'faraday'
require 'active_support/core_ext/object/to_query'

require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect 'api' => 'API'
loader.inflector.inflect 'version' => 'VERSION'
loader.setup

module Icinga2
end
