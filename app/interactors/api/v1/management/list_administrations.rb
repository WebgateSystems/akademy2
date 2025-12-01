# frozen_string_literal: true

module Api
  module V1
    module Management
      class ListAdministrations < BaseInteractor
        def call
          authorize!
          load_administrations
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

        def load_administrations
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          Rails.logger.debug '=== ListAdministrations DEBUG ==='
          Rails.logger.debug "Current user: #{current_user.id} (#{current_user.email})"
          Rails.logger.debug "School: #{school.id} (#{school.name})"

          page = (context.params[:page] || 1).to_i
          per_page = (context.params[:per_page] || 20).to_i
          offset = (page - 1) * per_page
          search_term = context.params[:search] || context.params[:q]

          base_query = build_base_query
          Rails.logger.debug "Base query SQL: #{base_query.to_sql}"
          Rails.logger.debug "Base query count: #{base_query.count}"

          base_query = apply_search_filter(base_query, search_term) if search_term.present?
          # Use preload instead of includes to avoid issues with distinct
          base_query = base_query.preload(:school, user_roles: :role).order(created_at: :desc)

          total_count = base_query.count
          Rails.logger.debug "Total count after filters: #{total_count}"

          administrations = base_query.limit(per_page).offset(offset)
          Rails.logger.debug "Administrations loaded: #{administrations.count}"

          administrations.each do |admin|
            roles_query = admin.user_roles.joins(:role).where(
              roles: { key: %w[principal school_manager] },
              user_roles: { school_id: school.id }
            )
            roles_list = roles_query.map { |ur| ur.role.key }.inspect
            Rails.logger.debug "  - Admin ID: #{admin.id}, Email: #{admin.email}, Roles: #{roles_list}"
          end

          context.form = administrations
          context.status = :ok
          context.serializer = AdministrationSerializer
          # Pass school_id to serializer via context (will be available in result.to_h)
          context.school_id = school.id
          Rails.logger.debug "School ID passed to serializer: #{context.school_id}"
          context.pagination = build_pagination(page, per_page, total_count, offset)
          Rails.logger.debug '=== END ListAdministrations DEBUG ==='
        end

        def build_base_query
          query = User.joins(:user_roles)
                      .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                      .where(user_roles: { school_id: school.id }, roles: { key: %w[principal school_manager] })
                      .distinct

          Rails.logger.debug "build_base_query - School ID: #{school.id}"
          Rails.logger.debug "build_base_query - SQL: #{query.to_sql}"

          query
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
