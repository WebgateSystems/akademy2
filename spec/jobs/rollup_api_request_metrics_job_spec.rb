# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RollupApiRequestMetricsJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  before do
    travel_to(Time.zone.parse('2025-01-01 12:00:00'))

    @first_bucket_event = Event.create!(
      event_type: 'api_request',
      user: alice,
      occurred_at: 10.minutes.ago,
      data: { 'ip' => '1.1.1.1', 'response_time_ms' => 100 }
    )

    @first_bucket_event_2 = Event.create!(
      event_type: 'api_request',
      user: bob,
      occurred_at: 7.minutes.ago,
      data: { 'ip' => '1.1.1.2', 'response_time_ms' => 200 }
    )

    @second_bucket_event = Event.create!(
      event_type: 'api_request',
      user: alice,
      occurred_at: 2.minutes.ago,
      data: { 'ip' => '1.1.1.1', 'response_time_ms' => 150 }
    )

    @other_event = Event.create!(
      event_type: 'login',
      user: alice,
      occurred_at: 5.minutes.ago
    )
  end

  after { travel_back }

  let(:alice) { create(:user) }
  let(:bob)   { create(:user) }

  describe '#perform' do
    context 'with explicit window' do
      before { described_class.new.perform(30) }

      it 'aggregates events 10 and 7 minutes ago into the first 5-min bucket' do
        metric = ApiRequestMetric.order(:bucket_start).first
        expect(metric.requests_count).to eq(2)
        expect(metric.unique_users_count).to eq(2)
        expect(metric.unique_ips_count).to eq(2)
        expect(metric.avg_response_time_ms).to eq(150.0)
      end

      it 'aggregates event 2 minutes ago into the second 5-min bucket' do
        metric = ApiRequestMetric.order(:bucket_start).second
        expect(metric.requests_count).to eq(1)
        expect(metric.unique_users_count).to eq(1)
        expect(metric.unique_ips_count).to eq(1)
        expect(metric.avg_response_time_ms).to eq(150.0)
      end

      it 'ignores non api_request events' do
        expect(ApiRequestMetric.count).to eq(2)
      end
    end

    context 'with default window' do
      it 'uses default 180 minutes window' do
        expect { described_class.new.perform }.to change(ApiRequestMetric, :count).from(0)
      end
    end
  end
end
