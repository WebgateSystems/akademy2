# frozen_string_literal: true

module Api
  module V1
    module Events
      class ListEvents < BaseInteractor
        def call
          authorize!
          load_events
        end

        private

        def authorize!
          policy = AdminPolicy.new(current_user, :admin)
          return if policy.access?

          context.message = ['Brak uprawnień']
          context.fail!
        end

        def current_user
          context.current_user
        end

        # rubocop:disable Metrics/PerceivedComplexity
        def load_events
          page = (context.params[:page] || 1).to_i
          per_page = (context.params[:per_page] || 20).to_i
          offset = (page - 1) * per_page

          base_query = Event.includes(:user).order(occurred_at: :desc, created_at: :desc)

          # Apply date filters if provided
          if context.params[:from].present?
            from_date = parse_datetime(context.params[:from])
            base_query = base_query.where('occurred_at >= ?', from_date) if from_date
          end

          if context.params[:to].present?
            to_date = parse_datetime(context.params[:to])
            # Treat `to` as inclusive for the whole minute (UI inputs are minute-precision).
            # Example: to="19:48" should include events up to 19:48:59.
            base_query = base_query.where('occurred_at < ?', to_date + 1.minute) if to_date
          end

          # Apply search filter if provided
          if context.params[:search].present?
            search_term = "%#{context.params[:search]}%"
            base_query = base_query.where(
              'event_type ILIKE ? OR data::text ILIKE ?',
              search_term, search_term
            )
          end

          # Optional IP filter (matches api_request data.ip)
          if context.params[:ip].present?
            ip_term = context.params[:ip].to_s.strip
            # Support simple wildcard: "1.2.3.*" or prefix "1.2.3."
            if ip_term.include?('*')
              like = ip_term.tr('*', '%')
              base_query = base_query.where("(data->>'ip') ILIKE ?", like)
            elsif ip_term.include?('/')
              # CIDR in SQL is possible with inet, but ip is stored as text in data.
              # As a pragmatic first step: prefix match on the network base.
              base_query = base_query.where("(data->>'ip') LIKE ?", "#{ip_term.split('/').first}%")
            else
              base_query = base_query.where("(data->>'ip') = ?", ip_term)
            end
          end

          total_count = base_query.count
          events = base_query.limit(per_page).offset(offset)

          context.form = events
          context.status = :ok
          context.serializer = EventSerializer
          context.pagination = build_pagination(page, per_page, total_count, offset)
        end
        # rubocop:enable Metrics/PerceivedComplexity

        def parse_datetime(date_string)
          return nil if date_string.blank?

          # Try parsing various formats: "DD.MM.YYYY HH:MM", ISO8601, etc.
          # IMPORTANT: interpret values in the app time zone (the UI is local-time based).
          begin
            Time.zone.strptime(date_string, '%d.%m.%Y %H:%M')
          rescue ArgumentError
            begin
              Time.zone.parse(date_string)
            rescue ArgumentError
              nil
            end
          end
        end

        def build_pagination(page, per_page, total_count, offset)
          {
            page: page,
            per_page: per_page,
            total: total_count,
            total_pages: (total_count.to_f / per_page).ceil,
            has_more: (offset + per_page) < total_count
          }
        end
      end
    end
  end
end
