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
            base_query = base_query.where('occurred_at <= ?', to_date) if to_date
          end

          # Apply search filter if provided
          if context.params[:search].present?
            search_term = "%#{context.params[:search]}%"
            base_query = base_query.where(
              'event_type ILIKE ? OR data::text ILIKE ?',
              search_term, search_term
            )
          end

          total_count = base_query.count
          events = base_query.limit(per_page).offset(offset)

          context.form = events
          context.status = :ok
          context.serializer = EventSerializer
          context.pagination = build_pagination(page, per_page, total_count, offset)
        end

        def parse_datetime(date_string)
          return nil if date_string.blank?

          # Try parsing various formats: DD.MM.YYYY HH:MM, YYYY-MM-DDTHH:MM, etc.
          begin
            DateTime.strptime(date_string, '%d.%m.%Y %H:%M')
          rescue ArgumentError
            begin
              DateTime.parse(date_string)
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
