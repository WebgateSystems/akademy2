# frozen_string_literal: true

module Api
  module V1
    module Students
      class LockStudent < BaseInteractor
        def call
          authorize!
          find_student
          lock_student
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

        def find_student
          context.student = User.joins(:roles).where(id: context.params[:id], roles: { key: 'student' }).first
          return if context.student

          context.message = ['Uczeń nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def lock_student
          if context.student.locked_at.present?
            unlock_student
          else
            lock_student_account
          end
          context.status = :ok
        end

        def unlock_student
          context.student.update(
            locked_at: nil,
            failed_attempts: 0,
            unlock_token: nil
          )
          context.form = { message: 'Konto ucznia zostało odblokowane przez administratora' }
        end

        def lock_student_account
          context.student.update(
            locked_at: Time.current,
            failed_attempts: 0
          )
          context.form = { message: 'Konto ucznia zostało zablokowane przez administratora' }
        end
      end
    end
  end
end
