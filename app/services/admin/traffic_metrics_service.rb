# frozen_string_literal: true

module Admin
  # rubocop:disable Metrics/ClassLength
  class TrafficMetricsService
    BUCKET_MINUTES = 5

    def initialize(range:)
      @range = range.to_s.presence || '24h'
    end

    # rubocop:disable Metrics/MethodLength
    def as_json
      cfg = range_config(range)
      from_time = cfg.fetch(:from_time)
      step_minutes = cfg.fetch(:step_minutes)
      source = cfg.fetch(:source)

      to_time = Time.current
      from_bucket = floor_to_minutes(from_time, step_minutes)
      to_bucket = floor_to_minutes(to_time, step_minutes)

      api_series = load_api_series(from_bucket: from_bucket, to_bucket: to_bucket, step_minutes: step_minutes,
                                   source: source)
      other_series = load_other_events_series(from_bucket: from_bucket, to_bucket: to_bucket,
                                              step_minutes: step_minutes)
      points = fill_points_with_zeros(
        api_series: api_series,
        other_series: other_series,
        from_bucket: from_bucket,
        to_bucket: to_bucket,
        step_minutes: step_minutes
      )

      {
        range: range,
        from: from_bucket.iso8601,
        to: to_bucket.iso8601,
        from_raw: from_time.iso8601,
        to_raw: to_time.iso8601,
        from_bucket: from_bucket.iso8601,
        to_bucket: to_bucket.iso8601,
        step_minutes: step_minutes,
        points: points.map do |row|
          { t: row[:t].iso8601, api: row[:api], other: row[:other] }
        end
      }
    end
    # rubocop:enable Metrics/MethodLength

    private

    attr_reader :range

    RANGE_MAP = {
      '3h' => { from_time: -> { 3.hours.ago }, step_minutes: BUCKET_MINUTES, source: :events },
      '8h' => { from_time: -> { 8.hours.ago }, step_minutes: BUCKET_MINUTES, source: :events },
      '24h' => { from_time: -> { 24.hours.ago }, step_minutes: 15, source: :metrics },
      '7d' => { from_time: -> { 7.days.ago }, step_minutes: 60, source: :metrics },
      '30d' => { from_time: -> { 30.days.ago }, step_minutes: 360, source: :metrics },
      '90d' => { from_time: -> { 90.days.ago }, step_minutes: 1440, source: :metrics }
    }.freeze

    def range_config(value)
      cfg = RANGE_MAP.fetch(value, RANGE_MAP.fetch('24h'))
      { from_time: cfg.fetch(:from_time).call, step_minutes: cfg.fetch(:step_minutes), source: cfg.fetch(:source) }
    end

    def floor_to_minutes(time, step_minutes)
      step_seconds = step_minutes.to_i.minutes
      Time.zone.at((time.to_i / step_seconds) * step_seconds)
    end

    def load_api_series(from_bucket:, to_bucket:, step_minutes:, source:)
      if source == :events
        return load_event_series(from_bucket: from_bucket, to_bucket: to_bucket,
                                 step_minutes: step_minutes)
      end

      expr = metric_bucket_sql(step_minutes)
      return {} unless expr

      ApiRequestMetric
        .where(bucket_start: from_bucket..to_bucket)
        .group(expr)
        .order(expr)
        .pluck(expr, Arel.sql('SUM(requests_count)::int'))
        .to_h
    end

    def load_event_series(from_bucket:, to_bucket:, step_minutes:)
      expr = event_bucket_sql(step_minutes)
      return {} unless expr

      to_exclusive = to_bucket + step_minutes.minutes

      Event
        .where(event_type: 'api_request', occurred_at: from_bucket...to_exclusive)
        .group(expr)
        .order(expr)
        .pluck(expr, Arel.sql('COUNT(*)::int'))
        .to_h
    end

    def load_other_events_series(from_bucket:, to_bucket:, step_minutes:)
      expr = event_bucket_sql(step_minutes)
      return {} unless expr

      to_exclusive = to_bucket + step_minutes.minutes

      Event
        .where(occurred_at: from_bucket...to_exclusive)
        .where.not(event_type: 'api_request')
        .group(expr)
        .order(expr)
        .pluck(expr, Arel.sql('COUNT(*)::int'))
        .to_h
    end

    EVENT_BUCKET_5M = <<~SQL.squish.freeze
      (date_trunc('minute', occurred_at) - (EXTRACT(minute FROM occurred_at)::int % 5) * interval '1 minute')
    SQL
    EVENT_BUCKET_15M = <<~SQL.squish.freeze
      (date_trunc('minute', occurred_at) - (EXTRACT(minute FROM occurred_at)::int % 15) * interval '1 minute')
    SQL
    EVENT_BUCKET_6H = <<~SQL.squish.freeze
      (date_trunc('hour', occurred_at) - (EXTRACT(hour FROM occurred_at)::int % 6) * interval '1 hour')
    SQL

    METRIC_BUCKET_15M = <<~SQL.squish.freeze
      (date_trunc('minute', bucket_start) - (EXTRACT(minute FROM bucket_start)::int % 15) * interval '1 minute')
    SQL
    METRIC_BUCKET_6H = <<~SQL.squish.freeze
      (date_trunc('hour', bucket_start) - (EXTRACT(hour FROM bucket_start)::int % 6) * interval '1 hour')
    SQL

    def event_bucket_sql(step_minutes)
      case step_minutes
      when 5 then Arel.sql(EVENT_BUCKET_5M)
      when 15 then Arel.sql(EVENT_BUCKET_15M)
      when 60 then Arel.sql("date_trunc('hour', occurred_at)")
      when 360 then Arel.sql(EVENT_BUCKET_6H)
      when 1440 then Arel.sql("date_trunc('day', occurred_at)")
      end
    end

    def metric_bucket_sql(step_minutes)
      case step_minutes
      when 15 then Arel.sql(METRIC_BUCKET_15M)
      when 60 then Arel.sql("date_trunc('hour', bucket_start)")
      when 360 then Arel.sql(METRIC_BUCKET_6H)
      when 1440 then Arel.sql("date_trunc('day', bucket_start)")
      end
    end

    def fill_points_with_zeros(api_series:, other_series:, from_bucket:, to_bucket:, step_minutes:)
      out = []
      t = from_bucket
      step = step_minutes.minutes
      while t <= to_bucket
        out << { t: t, api: api_series[t] || 0, other: other_series[t] || 0 }
        t += step
      end
      out
    end
  end
  # rubocop:enable Metrics/ClassLength
end
