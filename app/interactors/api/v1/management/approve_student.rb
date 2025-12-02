# frozen_string_literal: true

module Api
  module V1
    module Management
      class ApproveStudent < BaseInteractor
        def call
          authorize!
          find_student
          approve_student
        end

        private

        def authorize!
          policy = SchoolManagementPolicy.new(current_user, :school_management)
          return if policy.access?

          # Allow teachers for students in their assigned classes
          return if teacher_can_approve?

          context.message = ['Brak uprawnień']
          context.fail!
        end

        def teacher_can_approve?
          return false unless current_user.roles.pluck(:key).include?('teacher')

          # Get teacher's assigned class IDs
          teacher_class_ids = current_user.teacher_class_assignments.pluck(:school_class_id)
          return false if teacher_class_ids.empty?

          # Check if student is enrolled in any of teacher's classes
          StudentClassEnrollment.exists?(
            student_id: context.params[:id],
            school_class_id: teacher_class_ids
          )
        end

        def current_user
          context.current_user
        end

        def school
          @school ||= begin
            user_school = current_user.school
            return user_school if user_school

            # Try principal/school_manager role first
            user_role = current_user.user_roles
                                    .joins(:role)
                                    .where(roles: { key: %w[principal school_manager] })
                                    .first
            return user_role.school if user_role

            # Try teacher role
            teacher_role = current_user.user_roles
                                       .joins(:role)
                                       .where(roles: { key: 'teacher' })
                                       .first
            teacher_role&.school
          end
        end

        def find_student
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          # For teachers, use simplified query (access already verified in authorize!)
          context.student = if teacher_access?
                              find_student_for_teacher
                            else
                              build_student_query.first
                            end

          return if context.student

          context.message = ['Uczeń nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def teacher_access?
          current_user.roles.pluck(:key).include?('teacher') &&
            !SchoolManagementPolicy.new(current_user, :school_management).access?
        end

        def find_student_for_teacher
          # Teacher access was verified in authorize!, just load the student
          User.joins(:user_roles)
              .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
              .where(id: context.params[:id],
                     user_roles: { school_id: school.id },
                     roles: { key: 'student' })
              .first
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

        def approve_student
          return if student_already_confirmed?

          enrollment = find_pending_enrollment
          return if enrollment.nil?

          enrollment.status = 'approved'
          if enrollment.save
            confirm_student_if_needed
            resolve_notification
            log_approval_event
            set_success_response
          else
            context.message = enrollment.errors.full_messages
            context.fail!
          end
        end

        def student_already_confirmed?
          return false if context.student.confirmed_at.blank?

          context.message = ['Uczeń jest już zatwierdzony']
          context.fail!
          true
        end

        def confirm_student_if_needed
          context.student.confirm if context.student.confirmed_at.blank?
          context.student.save
        end

        def find_pending_enrollment
          enrollment = context.student.student_class_enrollments
                              .where(status: 'pending')
                              .first

          return enrollment if enrollment

          context.message = ['Uczeń nie ma oczekujących zapisów do klasy']
          context.fail!
          nil
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
