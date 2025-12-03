# frozen_string_literal: true

module Api
  module V1
    module Management
      class DestroyStudent < BaseInteractor
        def call
          authorize!
          find_student
          destroy_student
        end

        private

        def authorize!
          policy = SchoolManagementPolicy.new(current_user, :school_management)
          return if policy.access?

          # Allow teachers for students in their assigned classes
          return if teacher_can_decline?

          context.message = ['Brak uprawnień']
          context.fail!
        end

        def teacher_can_decline?
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
          # Find by enrollment in teacher's class - no need to check user_roles
          User.joins('INNER JOIN student_class_enrollments ' \
                     'ON student_class_enrollments.student_id = users.id')
              .joins('INNER JOIN school_classes ' \
                     'ON school_classes.id = student_class_enrollments.school_class_id')
              .where(id: context.params[:id],
                     school_classes: { school_id: school.id })
              .distinct
              .first
        end

        def build_student_query
          # Find student by enrollment in school's class
          # No need to check user_roles - if they have enrollment, they're a student
          # Don't filter by academic year - student may be in any class of this school
          User.joins('INNER JOIN student_class_enrollments ' \
                     'ON student_class_enrollments.student_id = users.id')
              .joins('INNER JOIN school_classes ' \
                     'ON school_classes.id = student_class_enrollments.school_class_id')
              .where(school_classes: { school_id: school.id })
              .where(id: context.params[:id])
              .distinct
        end

        def destroy_student
          # Resolve notifications before removing enrollment
          resolve_notifications

          # Get the enrollment(s) for this school
          enrollments_in_school = context.student.student_class_enrollments
                                         .joins(:school_class)
                                         .where(school_classes: { school_id: school.id })

          if enrollments_in_school.any?
            # Remove enrollments from this school only, not the student
            enrollments_in_school.destroy_all

            # Clear school_id from user if it matches this school
            context.student.update_column(:school_id, nil) if context.student.school_id == school.id

            # Student keeps their account and role - they can join another class/school
            context.status = :no_content
          else
            # No enrollments found - shouldn't happen, but handle gracefully
            context.message = ['Uczeń nie ma zapisów w tej szkole']
            context.status = :not_found
            context.fail!
          end
        end

        def resolve_notifications
          NotificationService.resolve_student_notification(
            student: context.student,
            school: school
          )

          # Also resolve enrollment request notifications
          context.student.student_class_enrollments.each do |enrollment|
            NotificationService.resolve_student_enrollment_request(
              student: context.student,
              school_class: enrollment.school_class
            )
          end
        end
      end
    end
  end
end
