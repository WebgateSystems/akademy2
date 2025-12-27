# frozen_string_literal: true

class PurgeOldApiRequestDataJob < BaseSidekiqJob
  sidekiq_options queue: :internal, retry: 3

  # Purge raw API request events and their aggregates older than N days (default: 90 ~= 3 months)
  def perform(older_than_days = 90)
    cutoff = older_than_days.to_i.days.ago

    Event.where(event_type: 'api_request').where('occurred_at < ?', cutoff).delete_all
    ApiRequestMetric.where('bucket_start < ?', cutoff).delete_all
  end
end
