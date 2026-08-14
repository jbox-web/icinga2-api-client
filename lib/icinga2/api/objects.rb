# frozen_string_literal: true

module Icinga2
  module API
    # Generic collection over any Icinga2 object type described by the catalog.
    #
    # It owns the three things every collection needs and that used to be
    # copied per class: building the endpoint, serialising filter/attrs/joins,
    # and flipping to POST when the URL would grow too long.
    class Objects

      # Past this, Icinga2 (and any proxy in front of it) starts rejecting the
      # request line, so the call is sent as a POST carrying the parameters in
      # its body with the method-override header.
      MAX_QUERY_LENGTH = 2_000

      METHOD_OVERRIDE_HEADERS = { 'X-HTTP-Method-Override' => 'GET' }.freeze

      attr_reader :api_client, :type, :context

      def initialize(api_client:, type:, catalog: TypeCatalog.default, context: {})
        @api_client = api_client
        @type       = catalog.fetch(type)
        @context    = context
      end

      # +force_post+ sends the request as a POST whatever its size. Downtime and
      # comment lookups have always done so, and their recorded cassettes match
      # on the method, so the choice stays explicit rather than size-driven.
      #
      # A block replaces the default construction, for the callers that need to
      # weave extra context into each object (Services#downtimes resolving each
      # downtime's service).
      def all(filter: nil, attrs: nil, joins: nil, force_post: false, &builder)
        params = build_params(filter, attrs, joins)
        builder ||= method(:build)

        fetch(params, force_post: force_post).filter_map { |result| builder.call(result['attrs']) if result['attrs'] }
      end

      alias where all

      # Look an object up by its full Icinga name ("web01!ssh!mail").
      # A filter matching nothing answers 404, which is an empty set here.
      def find(name)
        all(filter: %(#{type.filter_variable}.__name=="#{escape(name)}")).first
      rescue Error::NotFound
        nil
      end

      # Resolve a batch of names in a single request, in the order asked for.
      # Names the server did not return are dropped rather than left as nil.
      #
      # Icinga2's `in` operator checks whether a value belongs to one of the
      # object's own arrays, so it cannot match a name against a list; a
      # disjunction is what resolves a batch in one round trip.
      def find_many(names)
        names = Array(names)
        return [] if names.empty?

        filter = names.map { |name| %(#{type.filter_variable}.__name=="#{escape(name)}") }.join('||')
        found  = all(filter: filter).to_h { |object| [object.__name, object] }

        names.filter_map { |name| found[name] }
      rescue Error::NotFound
        []
      end

      # Escape a value for interpolation inside an Icinga2 filter string.
      #
      # Filter strings are double-quoted, so a name carrying a quote or a
      # backslash closes the string early and yields a filter the server cannot
      # parse. Public because every caller that builds a filter by hand needs
      # it, not just this class.
      def self.escape(value)
        value.to_s.gsub('\\', '\\\\\\\\').gsub('"', '\\"')
      end

      # The class objects of this type are built with: the dedicated one when
      # the gem models it, GenericObject otherwise.
      def object_class
        @object_class ||=
          if API.const_defined?(type.name, false)
            candidate = API.const_get(type.name, false)
            candidate.is_a?(Class) && candidate <= Resource ? candidate : GenericObject
          else
            GenericObject
          end
      end

      private

      def fetch(params, force_post: false)
        path = "/objects/#{type.endpoint}"

        if force_post || oversized?(params)
          api_client.api.post(path, params: params, headers: METHOD_OVERRIDE_HEADERS)
        else
          api_client.api.get(path, query: params)
        end
      end

      # Measured on the request line as it will actually be sent: percent-
      # encoded, every parameter included. Counting raw bytes underestimates by
      # up to a factor of three (a double quote becomes %22), which would let a
      # query the server rejects go out as a GET.
      def oversized?(params)
        encoded_length(params) > MAX_QUERY_LENGTH
      end

      def encoded_length(params)
        params.sum do |key, value|
          encoded_key = CGI.escape(key.to_s).bytesize

          # +2 per pair: the '=' and the '&' joining it to the next one.
          Array(value).sum { |item| encoded_key + CGI.escape(item.to_s).bytesize + 2 }
        end
      end

      def build_params(filter, attrs, joins)
        { filter: filter, attrs: attrs, joins: joins }.filter_map do |key, value|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          [key, value]
        end.to_h
      end

      # icinga_type is only meaningful to GenericObject, which consumes it in
      # its constructor. Passing it to a plain Resource subclass (Downtime,
      # Comment, Host, Service) would store it as a regular attribute and make
      # it surface in #to_h.
      def build(attrs)
        args = attrs.merge(context).merge(api_client: api_client)
        args[:icinga_type] = type.name if object_class <= GenericObject

        object_class.new args
      end

      def escape(name)
        self.class.escape(name)
      end

    end
  end
end
