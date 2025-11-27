# frozen_string_literal: true

module Api
  module V1
    module Students
      class ListStudents < BaseInteractor
        def call
          authorize!
          load_students
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

        # rubocop:disable Metrics/MethodLength
        def load_students
          page = (context.params[:page] || 1).to_i
          per_page = (context.params[:per_page] || 20).to_i
          offset = (page - 1) * per_page
          search_term = context.params[:search] || context.params[:q]

          base_query = build_base_query
          base_query = apply_search_filter(base_query, search_term) if search_term.present?
          base_query = base_query.includes(:school).order(created_at: :desc)

          total_count = base_query.count
          students = base_query.limit(per_page).offset(offset)

          context.form = students
          context.status = :ok
          context.serializer = StudentSerializer
          context.pagination = build_pagination(page, per_page, total_count, offset)
        end
        # rubocop:enable Metrics/MethodLength

        def build_base_query
          User.joins(:roles).where(roles: { key: 'student' }).distinct
        end

        def apply_search_filter(base_query, search_term)
          search_pattern = "%#{search_term}%"
          base_query.left_joins(:school).where(
            'users.first_name ILIKE ? OR users.last_name ILIKE ? OR ' \
            'users.email ILIKE ? OR users.metadata::text ILIKE ? OR schools.name ILIKE ?',
            search_pattern, search_pattern, search_pattern, search_pattern, search_pattern
          )
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
