# frozen_string_literal: true

module Api
  module V1
    module Management
      class ResendInviteStudent < BaseInteractor
        def call
          authorize!
          find_student
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

        def find_student
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          context.student = build_student_query.first

          return if context.student

          context.message = ['Uczeń nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def build_student_query
          User.joins(:user_roles)
              .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
              .joins('INNER JOIN student_class_enrollments ' \
                     'ON student_class_enrollments.student_id = users.id')
              .joins('INNER JOIN school_classes ' \
                     'ON school_classes.id = student_class_enrollments.school_class_id')
              .where(school_classes: { year: school.current_academic_year_value, school_id: school.id })
              .where(id: context.params[:id],
                     user_roles: { school_id: school.id },
                     roles: { key: 'student' })
              .distinct
        end

        def resend_confirmation_email
          context.student.send_confirmation_instructions
          context.form = { message: 'Zaproszenie zostało wysłane ponownie' }
          context.status = :ok
        end
      end
    end
  end
end
