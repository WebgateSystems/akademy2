# frozen_string_literal: true

module Api
  module V1
    module Management
      class LockTeacher < BaseInteractor
        def call
          authorize!
          find_teacher
          lock_teacher
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

        def find_teacher
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          context.teacher = User.joins(:user_roles)
                                .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                                .where(id: context.params[:id],
                                       user_roles: { school_id: school.id },
                                       roles: { key: 'teacher' })
                                .distinct
                                .first

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
          context.form = { message: 'Konto nauczyciela zostało odblokowane' }
        end

        def lock_teacher_account
          context.teacher.update(
            locked_at: Time.current,
            failed_attempts: 0
          )
          context.form = { message: 'Konto nauczyciela zostało zablokowane' }
        end
      end
    end
  end
end
