# frozen_string_literal: true

class RollupApiRequestMetricsJob < BaseSidekiqJob
  sidekiq_options queue: :internal, retry: 3

  BUCKET_MINUTES = 5

  def perform(since_minutes = 180)
    window_start = since_minutes.to_i.minutes.ago
    window_end = Time.current

    upsert_rows(bucket_query(window_start, window_end))
  end

  private

  # rubocop:disable Rails/SkipsModelValidations
  def upsert_rows(rows)
    now = Time.current
    rows.each do |row|
      ApiRequestMetric.upsert(
        {
          bucket_start: row['bucket_start'],
          requests_count: row['requests_count'],
          unique_users_count: row['unique_users_count'],
          unique_ips_count: row['unique_ips_count'],
          avg_response_time_ms: row['avg_response_time_ms'],
          updated_at: now,
          created_at: now
        },
        unique_by: :index_api_request_metrics_on_bucket_start
      )
    end
  end
  # rubocop:enable Rails/SkipsModelValidations

  # rubocop:disable Metrics/MethodLength
  def bucket_query(from_time, to_time)
    # Postgres: floor occurred_at into 5-minute buckets
    sql = <<~SQL.squish
      SELECT
        (date_trunc('minute', occurred_at) - (EXTRACT(minute FROM occurred_at)::int % #{BUCKET_MINUTES}) * interval '1 minute') AS bucket_start,
        COUNT(*)::int AS requests_count,
        COUNT(DISTINCT user_id)::int AS unique_users_count,
        COUNT(DISTINCT (data->>'ip'))::int AS unique_ips_count,
        AVG((data->>'response_time_ms')::float) AS avg_response_time_ms
      FROM events
      WHERE event_type = 'api_request'
        AND occurred_at >= $1
        AND occurred_at < $2
      GROUP BY bucket_start
      ORDER BY bucket_start ASC
    SQL

    binds = [
      ActiveRecord::Relation::QueryAttribute.new('from', from_time, ActiveRecord::Type::DateTime.new),
      ActiveRecord::Relation::QueryAttribute.new('to', to_time, ActiveRecord::Type::DateTime.new)
    ]

    ActiveRecord::Base.connection.exec_query(sql, 'RollupApiRequestMetrics', binds).to_a
  end
  # rubocop:enable Metrics/MethodLength
end
