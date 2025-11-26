# frozen_string_literal: true

module Api
  module V1
    module Teachers
      class ResendInviteTeacher < BaseInteractor
        def call
          authorize!
          find_teacher
          resend_confirmation_email
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

        def find_teacher
          context.teacher = User.joins(:roles).where(id: context.params[:id], roles: { key: 'teacher' }).first
          return if context.teacher

          context.message = ['Nauczyciel nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def resend_confirmation_email
          context.teacher.send_confirmation_instructions
          context.form = { message: 'Zaproszenie zostało wysłane ponownie' }
          context.status = :ok
        end
      end
    end
  end
end
