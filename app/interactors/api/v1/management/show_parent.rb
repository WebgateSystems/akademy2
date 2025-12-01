# frozen_string_literal: true

module Api
  module V1
    module Management
      class ShowParent < BaseInteractor
        def call
          authorize!
          find_parent
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
            user_school = current_user.school
            return user_school if user_school

            user_role = current_user.user_roles
                                    .joins(:role)
                                    .where(roles: { key: %w[principal school_manager] })
                                    .first
            user_role&.school
          end
        end

        def find_parent
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          parent = load_parent_from_school
          return unless parent

          context.form = parent
          context.status = :ok
          context.serializer = ParentSerializer
          context.school_id = school.id
        end

        def load_parent_from_school
          parent = User.joins(:user_roles)
                       .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                       .where(id: context.params[:id],
                              user_roles: { school_id: school.id },
                              roles: { key: 'parent' })
                       .preload(:school)
                       .distinct
                       .first

          return parent if parent

          context.message = ['Rodzic nie został znaleziony']
          context.status = :not_found
          context.fail!
          nil
        end
      end
    end
  end
end
