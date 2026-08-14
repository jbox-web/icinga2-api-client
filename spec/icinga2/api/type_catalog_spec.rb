# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::TypeCatalog do

  subject(:catalog) { described_class.new(fixture_path) }

  let(:fixture_path) { File.expand_path('../../fixtures/type_catalog.json', __dir__) }

  describe '#names' do
    it 'returns the Icinga type names, sorted' do
      expect(catalog.names).to eq %w[Host Notification Widget]
    end
  end

  describe '#fetch' do
    context 'when given the Icinga type name' do
      it 'returns the type' do
        expect(catalog.fetch('Notification').name).to eq 'Notification'
      end
    end

    context 'when given a snake_case symbol' do
      it 'returns the type' do
        expect(catalog.fetch(:notification).name).to eq 'Notification'
      end
    end

    context 'when given an unknown type' do
      it 'raises UnknownType' do
        expect {
          catalog.fetch(:service_group)
        }.to raise_error(Icinga2::API::Error::UnknownType, /ServiceGroup/)
      end
    end
  end

  describe '#key?' do
    it 'answers without raising' do
      expect(catalog.key?(:notification)).to be true
      expect(catalog.key?(:service_group)).to be false
    end
  end

  describe 'Type' do
    subject(:type) { catalog.fetch(:notification) }

    it 'exposes the endpoint path' do
      expect(type.endpoint).to eq 'notifications'
    end

    it 'exposes the plural name' do
      expect(type.plural_name).to eq 'Notifications'
    end

    # Icinga2 filters address objects through a variable named after the type,
    # lowercased and unseparated: `scheduleddowntime.name`, not
    # `scheduled_downtime.name`. A wrong prefix answers 404 "No objects found"
    # rather than an explicit error, so it must be derived, never typed.
    it 'exposes the filter variable name' do
      expect(type.filter_variable).to eq 'notification'
      expect(catalog.fetch(:host).filter_variable).to eq 'host'
    end

    it 'exposes the inheritance chain' do
      expect(type.base_chain).to eq %w[CustomVarObject ConfigObject Object]
    end

    it 'exposes the resolved fields' do
      expect(type.fields.keys).to include('host_name', 'period', 'users', '__name')
    end

    describe '#field?' do
      it 'is true for a declared field' do
        expect(type.field?('period')).to be true
        expect(type.field?(:period)).to be true
      end

      it 'is false for an undeclared field' do
        expect(type.field?('nope')).to be false
      end
    end

    it 'is frozen, along with its fields' do
      expect(type).to be_frozen
      expect(type.fields).to be_frozen
      expect(type.relations).to be_frozen
    end

    # .default is memoized for the whole process, so a shallow freeze would let
    # one accidental write corrupt the catalog for every later caller.
    it 'is frozen all the way down' do
      expect(type.fields['host_name']).to be_frozen
      expect { type.fields['host_name']['type'] = 'MUTE' }.to raise_error(FrozenError)
    end

    it 'freezes the values inside a field too' do
      expect(type.fields['host_name']['type']).to be_frozen
      expect(type.base_chain.first).to be_frozen
    end
  end

  describe 'Relation' do
    subject(:type) { catalog.fetch(:notification) }

    it 'exposes the referenced type and the navigation name' do
      relation = type.relation('host_name')
      expect(relation.ref_type).to eq 'Host'
      expect(relation.navigation_name).to eq 'host'
      expect(relation.array_rank).to eq 0
    end

    describe '#collection?' do
      it 'is false when array_rank is zero' do
        expect(type.relation('host_name').collection?).to be false
      end

      it 'is true when array_rank is above zero' do
        expect(type.relation('users').collection?).to be true
      end
    end

    describe '#relation' do
      it 'returns nil for a field that declares no reference' do
        expect(type.relation('service_name')).to be_nil
      end
    end
  end

  describe '.default' do
    subject(:catalog) { described_class.default }

    it 'loads the snapshot shipped with the gem' do
      expect(catalog.names).to include('Host', 'Service', 'Notification', 'User', 'UserGroup',
                                       'TimePeriod', 'HostGroup', 'ServiceGroup', 'Dependency',
                                       'ScheduledDowntime', 'Downtime', 'Comment')
    end

    it 'is memoized' do
      first = described_class.default
      expect(described_class.default).to be first
    end

    it 'maps every type to its endpoint' do
      expect(catalog.fetch(:scheduled_downtime).endpoint).to eq 'scheduleddowntimes'
    end
  end
end
