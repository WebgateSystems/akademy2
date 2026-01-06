# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::TrafficMetricsService, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.zone.parse('2025-01-01 12:00:00') }

  before { travel_to(now) }
  after { travel_back }

  describe '#as_json' do
    context 'with default range (24h)' do
      subject(:service) { described_class.new(range: nil) }

      before do
        # создаём метрики и события прямо здесь
        ApiRequestMetric.create!(bucket_start: now - 24.hours, requests_count: 10)
        ApiRequestMetric.create!(bucket_start: now - 24.hours + 15.minutes, requests_count: 5)
        Event.create!(event_type: 'api_request', occurred_at: now - 24.hours)
        Event.create!(event_type: 'login', occurred_at: now - 24.hours)
      end

      it 'returns structured metrics json' do
        result = service.as_json

        expect(result[:range]).to eq('24h')
        expect(result[:step_minutes]).to eq(15)
        expect(result[:points]).to all(include(:t, :api, :other))
      end

      it 'fills missing buckets with zeros' do
        result = service.as_json
        first_point = result[:points].first

        expect(first_point[:api]).to eq(10)
        expect(first_point[:other]).to eq(1)
      end
    end

    context 'with short range (3h → events source)' do
      subject(:service) { described_class.new(range: '3h') }

      before do
        Event.create!(event_type: 'api_request', occurred_at: now - 3.hours)
        Event.create!(event_type: 'login', occurred_at: now - 3.hours)
      end

      it 'uses events instead of metrics' do
        result = service.as_json

        expect(result[:step_minutes]).to eq(5)
        first_point = result[:points].first
        expect(first_point[:api]).to eq(1)
        expect(first_point[:other]).to eq(1)
      end
    end

    context 'when no data exists' do
      subject(:service) { described_class.new(range: '7d') }

      it 'returns zero-filled points' do
        result = service.as_json

        expect(result[:points]).not_to be_empty
        expect(result[:points].all? { |p| p[:api] == 0 && p[:other] == 0 }).to be(true)
      end
    end
  end
end
