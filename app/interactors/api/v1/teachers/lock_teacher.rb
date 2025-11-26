# frozen_string_literal: true

module Api
  module V1
    module Teachers
      class LockTeacher < BaseInteractor
        def call
          authorize!
          find_teacher
          lock_teacher
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

        def lock_teacher
          if context.teacher.locked_at.present?
            unlock_teacher
          else
            lock_teacher_account
          end
          context.status = :ok
        end

        def unlock_teacher
          context.teacher.update(
            locked_at: nil,
            failed_attempts: 0,
            unlock_token: nil
          )
          context.form = { message: 'Konto nauczyciela zostało odblokowane przez administratora' }
        end

        def lock_teacher_account
          context.teacher.update(
            locked_at: Time.current,
            failed_attempts: 0
          )
          context.form = { message: 'Konto nauczyciela zostało zablokowane przez administratora' }
        end
      end
    end
  end
end
