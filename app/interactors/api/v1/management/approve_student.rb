# frozen_string_literal: true

module Api
  module V1
    module Management
      class ApproveStudent < BaseInteractor
        CURRENT_ACADEMIC_YEAR = '2025/2026'

        def call
          authorize!
          find_student
          approve_student
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
              .joins('LEFT JOIN student_class_enrollments ' \
                     'ON student_class_enrollments.student_id = users.id')
              .joins('LEFT JOIN school_classes ' \
                     'ON school_classes.id = student_class_enrollments.school_class_id ' \
                     "AND school_classes.year = '#{CURRENT_ACADEMIC_YEAR}'")
              .where(id: context.params[:id],
                     user_roles: { school_id: school.id },
                     roles: { key: 'student' })
              .distinct
        end

        def approve_student
          return if already_confirmed?

          context.student.confirm
          if context.student.save
            resolve_notification
            log_approval_event
            set_success_response
          else
            context.message = context.student.errors.full_messages
            context.fail!
          end
        end

        def already_confirmed?
          return false if context.student.confirmed_at.blank?

          context.message = ['Uczeń jest już zatwierdzony']
          context.fail!
          true
        end

        def resolve_notification
          NotificationService.resolve_student_notification(
            student: context.student,
            school: school
          )
        end

        def log_approval_event
          EventLogger.log(
            event_type: 'student_approved',
            user: current_user,
            school: school,
            data: {
              student_id: context.student.id,
              student_email: context.student.email
            },
            client: 'web'
          )
        end

        def set_success_response
          context.form = context.student
          context.status = :ok
          context.serializer = StudentSerializer
        end
      end
    end
  end
end
