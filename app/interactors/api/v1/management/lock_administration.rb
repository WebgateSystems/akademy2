# frozen_string_literal: true

module Api
  module V1
    module Management
      class LockAdministration < BaseInteractor
        def call
          authorize!
          find_administration
          prevent_self_lock
          lock_administration
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

          context.administration = User.joins(:user_roles)
                                       .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                                       .where(id: context.params[:id],
                                              user_roles: { school_id: school.id },
                                              roles: { key: %w[principal school_manager] })
                                       .distinct
                                       .first

          return if context.administration

          context.message = ['Użytkownik administracji nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def prevent_self_lock
          return unless context.administration.id == current_user.id

          context.message = ['Nie możesz zablokować własnego konta']
          context.status = :unprocessable_entity
          context.fail!
        end

        def lock_administration
          if context.administration.locked_at.present?
            unlock_administration
          else
            lock_administration_account
          end
          context.form = context.administration
          context.status = :ok
          context.serializer = AdministrationSerializer
          context.school_id = school.id
        end

        def unlock_administration
          context.administration.update(
            locked_at: nil,
            failed_attempts: 0,
            unlock_token: nil
          )
        end

        def lock_administration_account
          context.administration.update(
            locked_at: Time.current,
            failed_attempts: 0
          )
        end
      end
    end
  end
end
