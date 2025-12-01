# frozen_string_literal: true

module Api
  module V1
    module Management
      class DestroyParent < BaseInteractor
        def call
          authorize!
          find_parent
          destroy_parent
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

          context.parent = User.joins(:user_roles)
                               .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                               .where(id: context.params[:id],
                                      user_roles: { school_id: school.id },
                                      roles: { key: 'parent' })
                               .distinct
                               .first

          return if context.parent

          context.message = ['Rodzic nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def destroy_parent
          if context.parent.destroy
            context.status = :no_content
          else
            context.message = context.parent.errors.full_messages
            context.fail!
          end
        end
      end
    end
  end
end
