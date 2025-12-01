# frozen_string_literal: true

module Api
  module V1
    module Management
      class ResendInviteAdministration < BaseInteractor
        def call
          authorize!
          find_administration
          resend_confirmation_email
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

        def resend_confirmation_email
          context.administration.send_confirmation_instructions
          context.form = { message: 'Zaproszenie zostało wysłane ponownie' }
          context.status = :ok
        end
      end
    end
  end
end
