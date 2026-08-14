# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Icinga2::API::TimePeriod do

  include WebMock::API

  subject(:period) do
    described_class.new(api_client: client, icinga_type: 'TimePeriod',
                        '__name' => '24x7', 'includes' => %w[workhours], 'excludes' => %w[holidays])
  end

  after { WebMock.reset! }


  let(:client) { Icinga2::API::Client.new('https://icinga2.example.net:5665', icinga_credentials) }
  let(:base)   { 'https://icinga2.example.net:5665/v1/objects' }

  def stub_periods(filter, name)
    stub_request(:get, "#{base}/timeperiods")
      .with(query: { 'filter' => filter })
      .to_return(status: 200, body: { results: [{ 'attrs' => { '__name' => name } }] }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  it 'is named after its Icinga __name' do
    expect(period.to_s).to eq '24x7'
  end

  describe '#included_periods' do
    it 'resolves them' do
      stub_periods('timeperiod.__name=="workhours"', 'workhours')
      expect(period.included_periods.map(&:__name)).to eq %w[workhours]
    end
  end

  describe '#excluded_periods' do
    it 'resolves them' do
      stub_periods('timeperiod.__name=="holidays"', 'holidays')
      expect(period.excluded_periods.map(&:__name)).to eq %w[holidays]
    end
  end
end
