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
          if context.teacher.confirmed_at.present?
            context.message = ['Nauczyciel jest już zatwierdzony']
            context.fail!
            return
          end

          context.teacher.confirm
          if context.teacher.save
            # Resolve notification for teacher approval
            NotificationService.resolve_teacher_notification(teacher: context.teacher, school: school)

            # Log the approval event
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

            context.form = context.teacher
            context.status = :ok
            context.serializer = TeacherSerializer
          else
            context.message = context.teacher.errors.full_messages
            context.fail!
          end
        end
      end
    end
  end
end
