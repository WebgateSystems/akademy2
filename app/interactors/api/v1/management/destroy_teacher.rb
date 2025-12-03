# frozen_string_literal: true

module Api
  module V1
    module Management
      class DestroyTeacher < BaseInteractor
        def call
          authorize!
          find_teacher
          destroy_teacher
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

        def destroy_teacher
          # If there's a pending enrollment, decline it (just remove enrollment)
          if context.enrollment&.status == 'pending'
            NotificationService.resolve_teacher_enrollment_request(teacher: context.teacher, school: school)
            context.enrollment.destroy!

            # Also clear any school associations for this school
            clear_school_associations

            # Teacher keeps their account and role - they can join another school
            context.status = :no_content
            return
          end

          # For approved teachers - remove from this school only
          if context.enrollment&.status == 'approved'
            context.enrollment.destroy!

            # Clear school associations
            clear_school_associations

            # Teacher keeps their account and role - they can join another school
            context.status = :no_content
            return
          end

          # Fallback for teachers without enrollment (legacy) - just remove from school
          clear_school_associations

          context.status = :no_content
        end

        def clear_school_associations
          # Clear school_id from user if it matches this school
          context.teacher.update_column(:school_id, nil) if context.teacher.school_id == school.id

          # Clear school_id from user_role (don't delete the role, just remove school association)
          # This keeps the teacher role but removes them from this specific school
          context.teacher.user_roles
                 .joins(:role)
                 .where(roles: { key: 'teacher' }, school_id: school.id)
                 .update_all(school_id: nil)
        end
      end
    end
  end
end
