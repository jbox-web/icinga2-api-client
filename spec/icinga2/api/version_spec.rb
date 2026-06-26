# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::VERSION do

  describe 'STRING' do
    it 'is a dotted version string' do
      expect(described_class::STRING).to match(/\A\d+\.\d+\.\d+/)
    end
  end

  describe '.gem_version' do
    it 'returns a Gem::Version built from STRING' do
      expect(Icinga2::API.gem_version).to eq Gem::Version.new(described_class::STRING)
    end
  end
end
