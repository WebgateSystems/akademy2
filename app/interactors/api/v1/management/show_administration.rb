# frozen_string_literal: true

module Api
  module V1
    module Management
      class ShowAdministration < BaseInteractor
        def call
          authorize!
          find_administration
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

        def find_administration
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          administration = load_administration_from_school
          return unless administration

          context.form = administration
          context.status = :ok
          context.serializer = AdministrationSerializer
          context.school_id = school.id
        end

        def load_administration_from_school
          # Find user who has at least one administration role (principal or school_manager) for this school
          # They may also have teacher role
          administration = User.joins(:user_roles)
                               .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                               .where(id: context.params[:id],
                                      user_roles: { school_id: school.id },
                                      roles: { key: %w[principal school_manager teacher] })
                               .where("EXISTS (SELECT 1 FROM user_roles ur2
                                      INNER JOIN roles r2 ON ur2.role_id = r2.id
                                      WHERE ur2.user_id = users.id
                                      AND ur2.school_id = ?
                                      AND r2.key IN ('principal', 'school_manager'))", school.id)
                               .preload(user_roles: :role)
                               .distinct
                               .first

          return administration if administration

          context.message = ['Użytkownik administracji nie został znaleziony']
          context.status = :not_found
          context.fail!
          nil
        end
      end
    end
  end
end
