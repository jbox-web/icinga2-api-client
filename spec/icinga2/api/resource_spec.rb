require 'spec_helper'

RSpec.describe Icinga2::API::Resource do

  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', version: 'v1', username: 'root', password: 'foo', verify_ssl: false) }

  subject { described_class.new(api_client: client.api, foo: 'bar', bar: 'foo') }

  describe '#to_yaml_properties' do
    it 'should return the list of attributes to render in the YAML dump' do
      expect(subject.to_yaml_properties).to eq [:@attributes]
    end
  end

  describe '#to_hash' do
    context 'when no option is passed' do
      it 'should return a hash of stored attributes' do
        expect(subject.to_hash).to eq({ foo: 'bar', bar: 'foo' })
      end
    end

    context 'when except option is passed' do
      it 'should return a hash of stored attributes' do
        expect(subject.to_hash(except: ['foo'])).to eq({ bar: 'foo' })
      end
    end

    context 'when only option is passed' do
      it 'should return a hash of stored attributes' do
        expect(subject.to_hash(only: ['foo'])).to eq({ foo: 'bar' })
      end
    end
  end

  describe '#dynamic_method' do
    it 'should return stored attributes' do
      expect(subject.foo).to eq 'bar'
      expect(subject.bar).to eq 'foo'
    end
  end

  describe '#method_missing' do
    context 'when method exist' do
      it 'should return the value' do
        expect(subject.foo).to eq 'bar'
      end
    end

    context 'when method dont exist' do
      it 'should call super (and raise error)' do
        expect {
          subject.baz
        }.to raise_error(NoMethodError)
      end
    end
  end
end
