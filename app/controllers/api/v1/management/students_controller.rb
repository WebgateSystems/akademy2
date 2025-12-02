# frozen_string_literal: true

module Api
  module V1
    module Management
      class StudentsController < Api::V1::Management::BaseController
        # Allow teachers to approve/decline students in their classes
        skip_before_action :require_school_management_access!, only: %i[approve decline]
        before_action :require_teacher_or_management_access!, only: %i[approve decline]

        def index
          result = Api::V1::Management::ListStudents.call(params:, current_user:)
          default_handler(result)
        end

        def show
          result = Api::V1::Management::ShowStudent.call(params:, current_user:)
          default_handler(result)
        end

        def create
          result = Api::V1::Management::CreateStudent.call(params:, current_user:)
          default_handler(result)
        end

        def update
          result = Api::V1::Management::UpdateStudent.call(params:, current_user:)
          default_handler(result)
        end

        def destroy
          result = Api::V1::Management::DestroyStudent.call(params:, current_user:) # Decline means destroy
          default_handler(result)
        end

        def resend_invite
          result = Api::V1::Management::ResendInviteStudent.call(params:, current_user:)
          default_handler(result)
        end

        def lock
          result = Api::V1::Management::LockStudent.call(params:, current_user:)
          default_handler(result)
        end

        def approve
          result = Api::V1::Management::ApproveStudent.call(params:, current_user:)
          default_handler(result)
        end

        def decline
          result = Api::V1::Management::DestroyStudent.call(params:, current_user:) # Decline means destroy
          default_handler(result)
        end

        private

        def require_teacher_or_management_access!
          return unless current_user

          current_user.roles.load unless current_user.roles.loaded?
          user_roles = current_user.roles.pluck(:key)

          # Allow school managers and principals
          return if user_roles.include?('principal') || user_roles.include?('school_manager')

          # Allow teachers for students in their assigned classes
          if user_roles.include?('teacher')
            student = User.find_by(id: params[:id])
            return if student && teacher_has_access_to_student?(student)
          end

          render json: { error: 'Brak uprawnień' }, status: :forbidden
        end

        def teacher_has_access_to_student?(student)
          # Get teacher's assigned class IDs
          teacher_class_ids = current_user.teacher_class_assignments.pluck(:school_class_id)
          return false if teacher_class_ids.empty?

          # Check if student is enrolled in any of teacher's classes
          student.student_class_enrollments.exists?(school_class_id: teacher_class_ids)
        end
      end
    end
  end
end
