# frozen_string_literal: true

module Api
  module V1
    module Management
      class UpdateTeacher < BaseInteractor
        def call
          authorize!
          find_teacher
          update_teacher
        end

        private

        def authorize!
          return if SchoolManagementPolicy.new(current_user, :school_management).access?

          context.fail!(message: ['Brak uprawnień'])
        end

        def current_user = context.current_user

        def school
          @school ||= current_user.school || current_user.user_roles.joins(:role)
                                                         .where(roles: { key: %w[principal
                                                                                 school_manager] }).first&.school
        end

        def find_teacher
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          context.teacher = User.joins(:user_roles).joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                                .where(id: context.params[:id], user_roles: { school_id: school.id },
                                       roles: { key: 'teacher' }).distinct.first
          return if context.teacher

          context.fail!(message: ['Nauczyciel nie został znaleziony'], status: :not_found)
        end

        def update_teacher
          update_params = build_update_params
          context.teacher.skip_reconfirmation! if email_changed?(update_params)

          return set_success_context if context.teacher.update(update_params)

          context.fail!(message: context.teacher.errors.full_messages)
        end

        def build_update_params
          params = teacher_params.to_h.tap do |p|
            merge_metadata(p)
            filter_blank_password(p)
          end
          params[:school_id] = school.id
          params
        end

        def email_changed?(params)
          params[:email].present? && context.teacher.email != params[:email]
        end

        def set_success_context
          update_school_manager_role
          context.form = context.teacher
          context.status = :ok
          context.serializer = TeacherSerializer
          context.school_id = school.id
        end

        def update_school_manager_role
          flag = context.params.dig(:teacher, :is_school_manager)
          return if flag.nil?

          manager_role = Role.find_by(key: 'school_manager')
          return unless manager_role

          existing = UserRole.find_by(user: context.teacher, role: manager_role, school: school)
          flag == true && !existing ? create_manager_role(manager_role) : existing&.destroy!
        end

        def create_manager_role(role)
          UserRole.create!(user: context.teacher, role: role, school: school)
        end

        def merge_metadata(params)
          current = context.teacher.metadata || {}
          if params[:metadata].present?
            params[:metadata] = current.deep_merge(params[:metadata].symbolize_keys)
          elsif (phone = context.params.dig(:teacher, :metadata, :phone))
            params[:metadata] = current.merge(phone: phone)
          end
        end

        def filter_blank_password(params)
          return if params[:password].present?

          params.delete(:password)
          params.delete(:password_confirmation)
        end

        def teacher_params
          p = context.params.is_a?(ActionController::Parameters) ? context.params : ActionController::Parameters.new(context.params)
          p.require(:teacher).permit(:first_name, :last_name, :email, :password, :password_confirmation, metadata: {})
        end
      end
    end
  end
end
