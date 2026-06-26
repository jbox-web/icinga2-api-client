# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::Resource do

  subject(:resource) { described_class.new(api_client: client.api, foo: 'bar', bar: 'foo') }

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }

  describe '#to_yaml_properties' do
    it 'returns the list of attributes to render in the YAML dump' do
      expect(resource.to_yaml_properties).to eq [:@attributes]
    end
  end

  describe '#to_hash' do
    context 'when no option is passed' do
      it 'returns a hash of stored attributes' do
        expect(resource.to_hash).to eq({ foo: 'bar', bar: 'foo' })
      end
    end

    context 'when except option is passed' do
      it 'returns a hash of stored attributes' do
        expect(resource.to_hash(except: ['foo'])).to eq({ bar: 'foo' })
      end
    end

    context 'when only option is passed' do
      it 'returns a hash of stored attributes' do
        expect(resource.to_hash(only: ['foo'])).to eq({ foo: 'bar' })
      end
    end

    context 'when called with a filter' do
      it 'does not mutate the stored attributes' do
        resource.to_hash(only: ['foo'])
        expect(resource.to_hash).to eq({ foo: 'bar', bar: 'foo' })
      end
    end
  end

  describe '#dynamic_method' do
    it 'returns stored attributes' do
      expect(resource.foo).to eq 'bar'
      expect(resource.bar).to eq 'foo'
    end
  end

  describe '#method_missing' do
    context 'when method exist' do
      it 'returns the value' do
        expect(resource.foo).to eq 'bar'
      end
    end

    context 'when assigning through a writer' do
      it 'stores the value' do
        resource.foo = 'updated'
        expect(resource.foo).to eq 'updated'
      end
    end

    context 'when method dont exist' do
      it 'calls super (and raise error)' do
        expect {
          resource.baz
        }.to raise_error(NoMethodError)
      end
    end
  end

  describe '#respond_to_missing?' do
    context 'when method exist' do
      it 'returns true' do
        expect(resource.respond_to?(:foo)).to be true
      end
    end

    context 'when method dont exist' do
      it 'returns false' do
        expect(resource.respond_to?(:baz)).to be false
      end
    end

    context 'when method is a writer' do
      it 'returns true' do
        expect(resource.respond_to?(:anything=)).to be true
      end
    end
  end

  describe 'attribute name colliding with a real method' do
    subject(:resource) { described_class.new(api_client: client.api, 'attributes' => 'boom') }

    it 'stores it as a plain attribute instead of invoking the method' do
      expect(resource.to_h[:attributes]).to eq 'boom'
    end
  end
end
