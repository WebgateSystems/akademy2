# frozen_string_literal: true

module Api
  module V1
    module Management
      class ListStudents < BaseInteractor
        CURRENT_ACADEMIC_YEAR = '2025/2026'

        def call
          authorize!
          load_students
        end

        private

        def authorize!
          policy = SchoolManagementPolicy.new(current_user, :school_management)
          return if policy.access?

          context.message = ['Brak uprawnień']
          context.fail!
        end

        def current_user
          context.current_user
        end

        def school
          @school ||= begin
            # Try direct school association first
            user_school = current_user.school
            return user_school if user_school

            # Fallback: get school from user_roles (for principal/school_manager)
            user_role = current_user.user_roles
                                    .joins(:role)
                                    .where(roles: { key: %w[principal school_manager] })
                                    .first
            user_role&.school
          end
        end

        def load_students
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          page = (context.params[:page] || 1).to_i
          per_page = (context.params[:per_page] || 20).to_i
          offset = (page - 1) * per_page
          search_term = context.params[:search] || context.params[:q]

          base_query = build_base_query
          base_query = apply_search_filter(base_query, search_term) if search_term.present?
          base_query = base_query.includes(:school, student_class_enrollments: :school_class)
                                 .order(created_at: :desc)

          total_count = base_query.count
          students = base_query.limit(per_page).offset(offset)

          context.form = students
          context.status = :ok
          context.serializer = StudentSerializer
          context.pagination = build_pagination(page, per_page, total_count, offset)
        end

        def build_base_query
          # Get students from current school
          # Include students with or without class assignment for current academic year
          User.joins(:user_roles)
              .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
              .joins('LEFT JOIN student_class_enrollments ON student_class_enrollments.student_id = users.id')
              .joins('LEFT JOIN school_classes ON school_classes.id = student_class_enrollments.school_class_id ' \
                     "AND school_classes.year = '#{CURRENT_ACADEMIC_YEAR}'")
              .where(user_roles: { school_id: school.id }, roles: { key: 'student' })
              .distinct
        end

        def apply_search_filter(base_query, search_term)
          search_pattern = "%#{search_term}%"
          base_query.left_joins(:school).where(
            'users.first_name ILIKE ? OR users.last_name ILIKE ? OR ' \
            'users.email ILIKE ? OR users.metadata::text ILIKE ?',
            search_pattern, search_pattern, search_pattern, search_pattern
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
