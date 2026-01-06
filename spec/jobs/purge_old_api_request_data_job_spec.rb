# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurgeOldApiRequestDataJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let(:cutoff_days) { 90 }

  let(:old_event) { Event.create!(event_type: 'api_request', occurred_at: 91.days.ago) }
  let(:old_metric) { ApiRequestMetric.create!(bucket_start: 91.days.ago, requests_count: 5) }
  let(:new_event) { Event.create!(event_type: 'api_request', occurred_at: 30.days.ago) }
  let(:new_metric) { ApiRequestMetric.create!(bucket_start: 30.days.ago, requests_count: 10) }

  before { travel_to(Time.zone.parse('2025-01-01 12:00:00')) }

  after { travel_back }

  describe '#perform' do
    it 'removes events older than cutoff' do
      expect { described_class.new.perform(cutoff_days) }
        .to change { Event.exists?(old_event.id) }
        .from(true).to(false)
    end

    it 'keeps events newer than cutoff' do
      expect { described_class.new.perform(cutoff_days) }
        .not_to change { Event.exists?(new_event.id) }.from(true)
    end

    it 'removes metrics older than cutoff' do
      expect { described_class.new.perform(cutoff_days) }
        .to change { ApiRequestMetric.exists?(old_metric.id) }
        .from(true).to(false)
    end

    it 'keeps metrics newer than cutoff' do
      expect { described_class.new.perform(cutoff_days) }
        .not_to change { ApiRequestMetric.exists?(new_metric.id) }.from(true)
    end

    it 'defaults to 90 days if no argument given' do
      old_event2 = Event.create!(event_type: 'api_request', occurred_at: 91.days.ago)
      expect { described_class.new.perform }
        .to change { Event.exists?(old_event2.id) }
        .from(true).to(false)
    end
  end
end
