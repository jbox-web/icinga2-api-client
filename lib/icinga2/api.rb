# frozen_string_literal: true

require_relative '../icinga2'

module Icinga2
  # Client for the Icinga2 REST API.
  #
  # Start from {Client}: it owns the connection and every collection hangs off
  # it. Objects are {Resource} subclasses exposing the server's attributes as
  # readers, with {GenericObject#navigate} to follow the references Icinga2
  # declares between them.
  #
  # @example
  #   client = Icinga2::API::Client.new(
  #     'https://icinga.example.net:5665',
  #     username: 'root', password: ENV.fetch('ICINGA_API_PASSWORD')
  #   )
  #   client.hosts.find('web01').services.find('ssh').downtimes
  #
  # @see https://www.icinga.com/docs/icinga2/latest/doc/12-icinga2-api/
  module API
  end
end
