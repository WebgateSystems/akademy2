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

        def update_teacher
          update_params = teacher_params.to_h
          merge_metadata(update_params)

          # Ensure school_id cannot be changed
          update_params[:school_id] = school.id

          # Skip Devise confirmation email when updating email (admin action)
          email_changed = update_params[:email].present? && context.teacher.email != update_params[:email]
          context.teacher.skip_reconfirmation! if email_changed

          if context.teacher.update(update_params)
            context.form = context.teacher
            context.status = :ok
            context.serializer = TeacherSerializer
          else
            context.message = context.teacher.errors.full_messages
            context.fail!
          end
        end

        def merge_metadata(update_params)
          if update_params[:metadata].present?
            current_metadata = context.teacher.metadata || {}
            update_params[:metadata] = current_metadata.deep_merge(update_params[:metadata].symbolize_keys)
          elsif context.params.dig(:teacher, :metadata, :phone).present?
            current_metadata = context.teacher.metadata || {}
            update_params[:metadata] = current_metadata.merge(
              phone: context.params.dig(:teacher, :metadata, :phone)
            )
          end
        end

        def teacher_params
          context.params.require(:teacher).permit(:first_name, :last_name, :email, :password,
                                                  :password_confirmation, metadata: {})
        end
      end
    end
  end
end
