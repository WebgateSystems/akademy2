# frozen_string_literal: true

namespace :metrics do
  namespace :api_requests do
    desc <<~DESC
      Rebuild ApiRequestMetric rows from raw api_request Events.

      Usage:
        bundle exec rake metrics:api_requests:rebuild
        bundle exec rake metrics:api_requests:rebuild FROM="2025-12-01 00:00" TO="2025-12-31 23:59"
        bundle exec rake metrics:api_requests:rebuild DAYS_BACK=90
        bundle exec rake metrics:api_requests:rebuild TRUNCATE=1

      Notes:
        - Works in 5-minute buckets (same as RollupApiRequestMetricsJob).
        - Runs in chunks (default 1 day) to avoid huge queries.
    DESC
    task rebuild: :environment do
      bucket_minutes = 5
      chunk_minutes = (ENV['CHUNK_MINUTES'].presence || (24 * 60)).to_i

      from_time =
        if ENV['FROM'].present?
          Time.zone.parse(ENV['FROM'])
        elsif ENV['DAYS_BACK'].present?
          ENV['DAYS_BACK'].to_i.days.ago
        else
          Event.where(event_type: 'api_request').minimum(:occurred_at)
        end

      to_time =
        if ENV['TO'].present?
          Time.zone.parse(ENV['TO'])
        else
          Time.current
        end

      if from_time.blank?
        puts '[metrics:api_requests:rebuild] No api_request events found. Nothing to do.'
        next
      end

      if ENV['TRUNCATE'].to_s == '1'
        puts '[metrics:api_requests:rebuild] TRUNCATE=1 -> deleting all ApiRequestMetric rows...'
        ApiRequestMetric.delete_all
      end

      puts "[metrics:api_requests:rebuild] Rebuilding from #{from_time} to #{to_time} "\
           "(bucket=#{bucket_minutes}m, chunk=#{chunk_minutes}m)"

      start_at = from_time
      total_upserts = 0

      while start_at < to_time
        end_at = [start_at + chunk_minutes.minutes, to_time].min
        rows = bucket_query(bucket_minutes: bucket_minutes, from_time: start_at, to_time: end_at)

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

        total_upserts += rows.length
        puts "[metrics:api_requests:rebuild] #{start_at}..#{end_at} -> buckets=#{rows.length}"
        start_at = end_at
      end

      puts "[metrics:api_requests:rebuild] Done. Upserted buckets=#{total_upserts}"
    end

    # rubocop:disable Metrics/MethodLength
    def bucket_query(bucket_minutes:, from_time:, to_time:)
      sql = <<~SQL.squish
        SELECT
          (date_trunc('minute', occurred_at) - (EXTRACT(minute FROM occurred_at)::int % #{bucket_minutes}) * interval '1 minute') AS bucket_start,
          COUNT(*)::int AS requests_count,
          COUNT(DISTINCT user_id)::int AS unique_users_count,
          COUNT(DISTINCT (data->>'ip'))::int AS unique_ips_count,
          AVG(NULLIF((data->>'response_time_ms'), '')::float) AS avg_response_time_ms
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

      ActiveRecord::Base.connection.exec_query(sql, 'RebuildApiRequestMetrics', binds).to_a
    end
    # rubocop:enable Metrics/MethodLength
  end
end
