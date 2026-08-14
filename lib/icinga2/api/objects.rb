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
      # @return [Integer] budget for the percent-encoded request line, in bytes
      MAX_QUERY_LENGTH = 2_000

      # @return [Hash{String => String}] header turning a POST into a GET
      METHOD_OVERRIDE_HEADERS = { 'X-HTTP-Method-Override' => 'GET' }.freeze

      # @return [Client] the client every request goes through
      attr_reader :api_client

      # @return [TypeCatalog::Type] the catalog entry this collection covers
      attr_reader :type

      # @return [Hash] extra attributes woven into every object built, e.g.
      #   `{ host: <Host> }` so a child can reach back to its parent
      attr_reader :context

      # @param api_client [Client]
      # @param type [Symbol, String] Icinga name or snake_case symbol
      # @param catalog [TypeCatalog] the catalog to resolve +type+ against
      # @param context [Hash] merged into every object built
      # @raise [Error::UnknownType] if the catalog does not carry that type
      def initialize(api_client:, type:, catalog: TypeCatalog.default, context: {})
        @api_client = api_client
        @type       = catalog.fetch(type)
        @context    = context
      end

      # Fetch the objects of this type.
      #
      # Sent as a GET, unless the percent-encoded request line passes
      # {MAX_QUERY_LENGTH} or +force_post+ is set, in which case it becomes a
      # POST carrying {METHOD_OVERRIDE_HEADERS}.
      #
      # @example Restrict both the rows and the columns
      #   collection.all(filter: 'user.__name=="admin"', attrs: %w[__name email])
      #
      # @param filter [String, nil] an Icinga filter; interpolate names through
      #   {.escape}
      # @param attrs [Array<String>, nil] attributes to return; omitting it
      #   returns the whole object
      # @param joins [Array<String>, nil] related objects to join in
      # @param force_post [Boolean] post whatever the size. Downtime and comment
      #   listings do, since that is the request shape their cassettes match on
      # @yieldparam attrs [Hash] one object's raw attributes
      # @yieldreturn [Object] what to build from them
      # @return [Array<Resource>] instances of {#object_class}, or of whatever
      #   the block returned
      # @raise [Error] on any transport or HTTP failure
      def all(filter: nil, attrs: nil, joins: nil, force_post: false, &builder)
        params = build_params(filter, attrs, joins)
        builder ||= method(:build)

        fetch(params, force_post: force_post).filter_map { |result| builder.call(result['attrs']) if result['attrs'] }
      end

      # @!method where(filter: nil, attrs: nil, joins: nil, force_post: false, &builder)
      #   Alias of {#all}, for call sites that read better as a query.
      #   @return [Array<Resource>]
      alias where all

      # Look an object up by its full Icinga name.
      #
      # @example
      #   collection.find('web01!ssh!mail')
      #
      # @param name [String] the `__name`, e.g. "web01!ssh" for a service
      # @return [Resource, nil] nil when nothing matches — Icinga2 answers 404
      #   for an empty result set, which is not treated as a failure here
      # @raise [Error] on any transport or HTTP failure other than that 404
      def find(name)
        all(filter: %(#{type.filter_variable}.__name=="#{escape(name)}")).first
      rescue Error::NotFound
        nil
      end

      # Resolve a batch of names in a single request.
      #
      # Icinga2's `in` operator checks whether a value belongs to one of the
      # object's own arrays, so it cannot match a name against a list; a
      # disjunction is what resolves a batch in one round trip.
      #
      # @param names [Array<String>, String]
      # @return [Array<Resource>] in the order asked for, with the names the
      #   server did not return dropped rather than left as nil. Empty input
      #   sends no request at all
      # @raise [Error] on any transport or HTTP failure other than a 404
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
      #
      # @example
      #   %(host.name=="#{Icinga2::API::Objects.escape(name)}")
      #
      # @param value [#to_s]
      # @return [String]
      def self.escape(value)
        value.to_s.gsub('\\', '\\\\\\\\').gsub('"', '\\"')
      end

      # The class objects of this type are built with: the dedicated one when
      # the gem models it, {GenericObject} otherwise.
      #
      # @return [Class]
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
