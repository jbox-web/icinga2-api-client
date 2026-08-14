# frozen_string_literal: true

# require ruby dependencies
# cgi/escape rather than cgi: the full CGI library is gone in Ruby 4.0, and
# CGI.escape/CGI.unescape is all this gem needs.
require 'cgi/escape'
require 'json'

# require external dependencies
require 'faraday'
require 'zeitwerk'

# load zeitwerk
Zeitwerk::Loader.for_gem.tap do |loader|
  loader.inflector.inflect 'api' => 'API'
  loader.inflector.inflect 'version' => 'VERSION'
  loader.setup
end

# Namespace of the gem. Everything user-facing lives under {Icinga2::API}.
module Icinga2
end
