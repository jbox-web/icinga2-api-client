# frozen_string_literal: true

# require ruby dependencies
require 'json'

# require external dependencies
require 'faraday'
require 'active_support/core_ext/object/to_query'
require 'zeitwerk'

# load zeitwerk
Zeitwerk::Loader.for_gem.tap do |loader|
  loader.inflector.inflect 'api' => 'API'
  loader.inflector.inflect 'version' => 'VERSION'
  loader.setup
end

module Icinga2
end
