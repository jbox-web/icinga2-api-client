# frozen_string_literal: true

require 'json'

# Builds the frozen type catalog shipped as data/icinga2_types.json out of a
# server's /v1/types response.
#
# Lives outside lib/ on purpose: this is build-time tooling, not part of the
# gem, and it is a plain .rb rather than inline rake code so that its constants
# do not leak to the top level.
module Icinga2TypesSnapshot

  # Only the types this gem models. The full catalog carries 39 queryable
  # types, most of them infrastructure (writers, loggers, connections) that
  # the gem has no business exposing.
  MODELLED_TYPES = %w[
    Comment
    Dependency
    Downtime
    Host
    HostGroup
    Notification
    ScheduledDowntime
    Service
    ServiceGroup
    TimePeriod
    User
    UserGroup
  ].freeze

  # Icinga's own attribute flags, minus the internal numeric "id" which
  # changes between builds and would churn the diff for nothing.
  KEPT_FLAGS = %w[config state required deprecated no_user_modify no_user_view].freeze

  SNAPSHOT_PATH = File.expand_path('../data/icinga2_types.json', __dir__)

  class << self

    # Either a saved /v1/types response (TYPES_JSON) or a live master.
    # A saved dump is what makes regeneration reviewable without handing
    # credentials to the task.
    def load_raw
      file = ENV.fetch('TYPES_JSON', nil)
      return JSON.parse(File.read(file)).fetch('results') if file

      require 'icinga2/api'
      interface.get('/types')
    end

    def build(raw)
      by_name = raw.to_h { |type| [type['name'], type] }

      MODELLED_TYPES.to_h do |name|
        type = by_name.fetch(name) { raise "type '#{name}' is absent from this server's catalog" }
        [name, describe(type, by_name)]
      end
    end

    def write(catalogue)
      File.write(SNAPSHOT_PATH, "#{JSON.pretty_generate({ 'types' => catalogue })}\n")
      SNAPSHOT_PATH
    end

    private

    def interface
      Icinga2::API::Interface.new(
        base_url:    ENV.fetch('ICINGA_API_URL'),
        username:    ENV.fetch('ICINGA_API_USER', 'root'),
        password:    ENV.fetch('ICINGA_API_PASSWORD'),
        ssl_options: { verify: ENV.fetch('ICINGA_API_VERIFY_SSL', 'true') == 'true' }
      )
    end

    def describe(type, by_name)
      fields = resolved_fields(type, by_name)

      {
        'name'        => type['name'],
        'plural_name' => type['plural_name'],
        'endpoint'    => type['plural_name'].downcase,
        'base_chain'  => base_chain(type['base'], by_name),
        'fields'      => fields.transform_values { |field| describe_field(field) },
        'relations'   => relations(fields)
      }
    end

    # A type's own "fields" holds only what it declares: CheckCommand declares
    # none at all, everything coming from Command. Walking the base chain is
    # therefore mandatory, not an optimisation.
    def resolved_fields(type, by_name)
      chain = [type['name'], *base_chain(type['base'], by_name)]

      # Reverse so the most general ancestor is merged first and the type's own
      # declaration wins on collision.
      chain.reverse.each_with_object({}) do |name, acc|
        acc.merge!(by_name.fetch(name, {}).fetch('fields', {}))
      end.sort.to_h
    end

    def base_chain(base, by_name)
      return [] if base.nil? || !by_name.key?(base)

      [base, *base_chain(by_name[base]['base'], by_name)]
    end

    def describe_field(field)
      flags = field.fetch('attributes', {})

      { 'type' => field['type'], 'array_rank' => field['array_rank'].to_i }
        .merge(KEPT_FLAGS.to_h { |flag| [flag, flags.fetch(flag, false)] })
    end

    def relations(fields)
      fields.filter_map do |name, field|
        next unless field['ref_type']

        [name, { 'ref_type'        => field['ref_type'],
                 'navigation_name' => field['navigation_name'],
                 'array_rank'      => field['array_rank'].to_i }]
      end.to_h
    end

  end

end
