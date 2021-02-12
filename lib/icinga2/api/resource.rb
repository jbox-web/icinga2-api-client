# frozen_string_literal: true

module Icinga2
  module API
    class Resource

      attr_reader :api_client

      def initialize(args = {})
        @api_client = args.delete(:api_client)
        @attributes = {}
        self.attributes = args
      end

      def attributes=(args = {})
        args.each do |key, value|
          send(:"#{key}=", value)
        end
      end

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

      def respond_to_missing?(method_name, include_private = false)
        @attributes.key?(method_name) || super
      end

      def to_hash(opts = {})
        except = opts.fetch(:except, [])
        only   = opts.fetch(:only, [])
        filter_hash(except, only)
      end

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
      def to_yaml_properties
        [:@attributes]
      end

      private

      def filter_hash(except = [], only = [])
        hash = @attributes
        hash.reject! { |key, _| except.include?(key.to_sym) || except.include?(key.to_s) } unless except.empty?
        hash.reject! { |key, _| !only.include?(key.to_sym) && !only.include?(key.to_s) } unless only.empty?
        hash
      end

    end
  end
end
