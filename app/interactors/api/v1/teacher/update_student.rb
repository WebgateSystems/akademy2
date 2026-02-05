# frozen_string_literal: true

module Api
  module V1
    module Teacher
      class UpdateStudent < BaseInteractor
        def call
          authorize!
          find_student
          update_student
        end

        private

        def authorize!
          return if current_user && teacher_role?

          context.fail!(message: ['Brak uprawnień'])
        end

        def teacher_role?
          current_user.user_roles.joins(:role).exists?(roles: { key: 'teacher' })
        end

        def current_user = context.current_user

        def school
          @school ||= current_user.school || current_user.user_roles.joins(:role)
                                                         .where(roles: { key: 'teacher' }).first&.school
        end

        def find_student
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          context.student = find_student_in_teacher_classes
          return if context.student

          context.fail!(message: ['Uczeń nie został znaleziony'], status: :not_found)
        end

        def find_student_in_teacher_classes
          teacher_class_ids = TeacherClassAssignment.where(teacher: current_user).pluck(:school_class_id)
          return nil if teacher_class_ids.empty?

          User.joins(:student_class_enrollments)
              .where(id: context.params[:id],
                     student_class_enrollments: { school_class_id: teacher_class_ids })
              .distinct.first
        end

        def update_student
          params = build_update_params
          skip_reconfirmation_if_email_changed(params)

          return set_success_context if context.student.update(params)

          context.fail!(message: context.student.errors.full_messages)
        end

        def build_update_params
          params = student_params.to_h
          merge_metadata(params)
          filter_blank_password(params)
          params[:school_id] = school.id
          params.delete(:school_class_id)
          params
        end

        def skip_reconfirmation_if_email_changed(params)
          return unless params[:email].present? && context.student.email != params[:email]

          context.student.skip_reconfirmation!
        end

        def set_success_context
          context.form = context.student
          context.status = :ok
          context.serializer = StudentSerializer
        end

        def merge_metadata(params)
          return if params[:metadata].blank?

          current = context.student.metadata || {}
          params[:metadata] = current.deep_merge(params[:metadata].symbolize_keys)
        end

        def filter_blank_password(params)
          return if params[:password].present?

          params.delete(:password)
          params.delete(:password_confirmation)
        end

        def student_params
          p = context.params.is_a?(ActionController::Parameters) ? context.params : ActionController::Parameters.new(context.params)
          p.require(:student).permit(:first_name, :last_name, :email, :password,
                                     :password_confirmation, :birthdate, metadata: {})
        end
      end
    end
  end
end
