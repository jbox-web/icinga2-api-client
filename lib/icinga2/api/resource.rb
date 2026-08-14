# frozen_string_literal: true

module Icinga2
  module API
    # Base class of every object the API returns.
    #
    # It keeps the raw `attrs` hash the server sent and exposes each key as a
    # reader and a writer through `method_missing`, so an attribute the gem has
    # never heard of is still reachable. Writers only touch the local copy;
    # nothing is sent back to Icinga2.
    #
    # @example
    #   host.address        # whatever the API returned
    #   host.respond_to?(:address)
    #   host.to_h(only: %i[__name state])
    class Resource

      # @return [Client] the client this object was fetched through
      attr_reader :api_client

      # @param args [Hash] the object's attributes, plus `:api_client`
      def initialize(args = {})
        @api_client = args.delete(:api_client)
        @attributes = {}
        self.attributes = args
      end

      # Merge attributes into the local store.
      #
      # @param args [Hash] keys are symbolized; existing ones are overwritten
      # @return [Hash] the attributes given
      def attributes=(args = {})
        # Write straight into the store: going through send(:"#{key}=") would
        # collide with real methods when an Icinga attribute is named like one
        # (e.g. "attributes").
        args.each do |key, value|
          @attributes[key.to_sym] = value
        end
      end

      # Expose every stored attribute as a reader, and any name as a writer.
      #
      # @param meth [Symbol]
      # @return [Object] the stored value, or the value just assigned
      # @raise [NoMethodError] reading an attribute the object does not carry
      def method_missing(meth, *args, &block)
        if meth.to_s =~ /^(.+)=$/
          @attributes[Regexp.last_match(1).to_sym] = args[0]
        elsif @attributes.key?(meth)
          @attributes[meth]
        else
          # You *must* call super if you don't handle the
          # method, otherwise you'll mess up Ruby's method
          # lookup.
          super
        end
      end

      # @param method_name [Symbol]
      # @param include_private [Boolean]
      # @return [Boolean] true for any stored attribute, and for any writer
      def respond_to_missing?(method_name, include_private = false)
        method_name.to_s.end_with?('=') || @attributes.key?(method_name) || super
      end

      # The stored attributes, optionally filtered. Never destructive: the
      # object keeps every attribute whatever is passed here.
      #
      # @param opts [Hash]
      # @option opts [Array<String, Symbol>] :except keys to drop
      # @option opts [Array<String, Symbol>] :only keys to keep
      # @return [Hash{Symbol => Object}]
      def to_hash(opts = {})
        except = opts.fetch(:except, [])
        only   = opts.fetch(:only, [])
        filter_hash(except, only)
      end

      # @!method to_h(opts = {})
      #   Alias of {#to_hash}.
      #   @return [Hash{Symbol => Object}]
      alias to_h to_hash

      # When using YAML.dump to look at objects attributes,
      # this method is called to get the list of object's attributes
      # to render in the dump.
      # By default it may contain all this attributes to render, which can make
      # the dump pretty big because of nested objects.
      # ---
      # - :@service
      # - :@host
      # - :@api_client
      # - :@attributes
      # Override it to only render the @attributes instance var.
      #
      # @return [Array<Symbol>]
      def to_yaml_properties
        [:@attributes]
      end

      private

      def filter_hash(except = [], only = [])
        hash = @attributes.dup
        hash.reject! { |key, _| except.include?(key.to_sym) || except.include?(key.to_s) } unless except.empty?
        hash.reject! { |key, _| !only.include?(key.to_sym) && !only.include?(key.to_s) } unless only.empty?
        hash
      end

    end
  end
end
