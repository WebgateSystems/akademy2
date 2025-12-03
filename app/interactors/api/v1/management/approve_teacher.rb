# frozen_string_literal: true

module Api
  module V1
    module Management
      class ApproveTeacher < BaseInteractor
        def call
          authorize!
          find_teacher
          approve_teacher
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

          # Find teacher by enrollment in school
          enrollment = TeacherSchoolEnrollment.joins(:teacher)
                                              .joins('INNER JOIN users ON ' \
                                                     'teacher_school_enrollments.teacher_id = users.id')
                                              .joins('INNER JOIN user_roles ON users.id = user_roles.user_id')
                                              .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                                              .where(teacher_school_enrollments: { school_id: school.id },
                                                     users: { id: context.params[:id] },
                                                     roles: { key: 'teacher' })
                                              .distinct
                                              .first

          if enrollment
            context.teacher = enrollment.teacher
            context.enrollment = enrollment
            return
          end

          # Fallback: find teacher by user_roles (for backward compatibility)
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

        def approve_teacher
          enrollment = context.enrollment || find_pending_enrollment

          if enrollment
            return if enrollment_already_approved?(enrollment)

            enrollment.status = 'approved'
            enrollment.joined_at = Time.current
            if enrollment.save
              confirm_teacher_if_needed
              update_teacher_school_assignment
              resolve_notification
              log_approval_event
              set_success_response
            else
              context.message = enrollment.errors.full_messages
              context.fail!
            end
          else
            # Fallback: old approval flow (for backward compatibility)
            if context.teacher.confirmed_at.present?
              context.message = ['Nauczyciel jest już zatwierdzony']
              context.fail!
              return
            end

            context.teacher.confirm
            if context.teacher.save
              NotificationService.resolve_teacher_notification(teacher: context.teacher, school: school)
              log_approval_event
              set_success_response
            else
              context.message = context.teacher.errors.full_messages
              context.fail!
            end
          end
        end

        def find_pending_enrollment
          context.teacher.teacher_school_enrollments
                 .where(school: school, status: 'pending')
                 .first
        end

        def enrollment_already_approved?(enrollment)
          return false unless enrollment.status == 'approved'

          context.message = ['Nauczyciel jest już zatwierdzony w tej szkole']
          context.fail!
          true
        end

        def confirm_teacher_if_needed
          context.teacher.confirm if context.teacher.confirmed_at.blank?
          context.teacher.save
        end

        def update_teacher_school_assignment
          context.teacher.update!(school: school) if context.teacher.school.nil?
          teacher_role = context.teacher.user_roles.joins(:role).find_by(roles: { key: 'teacher' })
          teacher_role&.update!(school: school) if teacher_role&.school.nil?
        end

        def resolve_notification
          NotificationService.resolve_teacher_enrollment_request(teacher: context.teacher, school: school)
        end

        def log_approval_event
          EventLogger.log(
            event_type: 'teacher_approved',
            user: current_user,
            school: school,
            data: {
              teacher_id: context.teacher.id,
              teacher_email: context.teacher.email
            },
            client: 'web'
          )
        end

        def set_success_response
          context.form = context.teacher
          context.status = :ok
          context.serializer = TeacherSerializer
        end
      end
    end
  end
end
