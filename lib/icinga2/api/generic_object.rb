# frozen_string_literal: true

module Icinga2
  module API
    # Base class for every object fetched through the generic collection layer.
    #
    # On top of Resource's attribute store it knows its own type, which lets it
    # resolve the references Icinga2 declares between objects (ref_type /
    # navigation_name / array_rank) without any per-type wiring.
    #
    # Navigation deliberately does NOT define readers named after the fields it
    # follows: `notification.period` keeps returning the string the API sent,
    # and the resolved TimePeriod is reached through #navigate(:period) or a
    # named shortcut on the dedicated subclass. Shadowing an attribute with an
    # object of a different class would silently break existing callers.
    class GenericObject < Resource

      attr_reader :icinga_type, :host, :service

      def initialize(args = {})
        @icinga_type = args.delete(:icinga_type)
        @host        = args.delete(:host)
        @service     = args.delete(:service)
        @type        = nil
        @memoized    = {}

        super
      end

      def full_name
        __name
      end

      alias to_s full_name

      # Memoize a navigation under +key+, nil results included: `@x ||= …`
      # would re-issue the request on every call whenever it resolves to
      # nothing, which is the common case for a host-level object.
      def memoized(key)
        return @memoized[key] if @memoized.key?(key)

        @memoized[key] = yield
      end

      # Resolve a declared reference into the object(s) it points at.
      # Returns nil (or [] for a list) when the field carries no value.
      def navigate(field)
        relation = type.relation(field.to_s)
        raise Error::UnknownRelation, "'#{type.name}' declares no reference on '#{field}'" if relation.nil?

        value = @attributes[field.to_sym]
        relation.collection? ? navigate_many(relation, value) : navigate_one(relation, value)
      end

      # The catalog entry describing this object's type.
      def type
        @type ||= TypeCatalog.default.fetch(icinga_type || self.class.name.split('::').last)
      end

      private

      # Resolve a Service from a (host_name, service_name) attribute pair.
      #
      # Icinga2 declares ref_type on every reference EXCEPT the ones pointing
      # at a service: no service_name field carries one, on any type. So this
      # arc cannot be derived from the catalog and is spelled out instead.
      #
      # An empty service_name means the object sits at host level (1 026 of the
      # notifications on the master this was checked against), which resolves
      # to nil without a request.
      def resolve_service(host_field: :host_name, service_field: :service_name)
        host_name    = @attributes[host_field].to_s
        service_name = @attributes[service_field].to_s
        return nil if host_name.empty? || service_name.empty?

        Objects.new(api_client: api_client, type: :service).find("#{host_name}!#{service_name}")
      end

      # The objects of +type+ listing this one among their groups.
      #
      # Membership is held by the member, not by the group, and Icinga2 only
      # matches it through .contains(): verified against a live master, the
      # `in` operator answers 404 "No objects found" on the same data.
      def members(type)
        collection = Objects.new(api_client: api_client, type: type)
        filter     = %(#{collection.type.filter_variable}.groups.contains("#{Objects.escape(full_name)}"))

        collection.all(filter: filter)
      end

      def navigate_one(relation, value)
        return nil if value.nil? || value.to_s.empty?

        collection_for(relation).find(value)
      end

      # One request for the whole list, not one per element.
      def navigate_many(relation, values)
        return [] if values.nil?

        collection_for(relation).find_many(Array(values))
      end

      def collection_for(relation)
        Objects.new(api_client: api_client, type: relation.ref_type)
      end

    end
  end
end
