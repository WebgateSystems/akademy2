# frozen_string_literal: true

module Api
  module V1
    module Management
      class ListTeachers < BaseInteractor
        def call
          authorize!
          load_teachers
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

        def load_teachers
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          page = (context.params[:page] || 1).to_i
          per_page = (context.params[:per_page] || 20).to_i
          offset = (page - 1) * per_page
          search_term = context.params[:search] || context.params[:q]

          base_query = build_base_query
          base_query = apply_search_filter(base_query, search_term) if search_term.present?
          base_query = base_query.includes(:school).order(created_at: :desc)

          total_count = base_query.count
          teachers = base_query.limit(per_page).offset(offset)

          context.form = teachers
          context.status = :ok
          context.serializer = TeacherSerializer
          context.pagination = build_pagination(page, per_page, total_count, offset)
          # Pass school_id to serializer (HandleStatusCode will pick it up)
          context.school_id = school.id
        end

        def build_base_query
          # Include teachers with approved enrollments OR pending enrollments OR old user_roles
          teacher_ids_with_enrollments = TeacherSchoolEnrollment.where(school: school,
                                                                       status: %w[
                                                                         approved pending
                                                                       ]).pluck(:teacher_id)
          teacher_ids_with_roles = User.joins(:user_roles)
                                       .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                                       .where(user_roles: { school_id: school.id }, roles: { key: 'teacher' })
                                       .pluck(:id)

          User.joins(:user_roles)
              .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
              .where(id: (teacher_ids_with_enrollments + teacher_ids_with_roles).uniq)
              .where(roles: { key: 'teacher' })
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
