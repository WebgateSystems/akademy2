# frozen_string_literal: true

module Api
  module V1
    module Teachers
      class UpdateTeacher < BaseInteractor
        def call
          authorize!
          find_teacher
          update_teacher
        end

        private

        def authorize!
          policy = AdminPolicy.new(current_user, :admin)
          return if policy.access?

          context.message = ['Brak uprawnień']
          context.fail!
        end

        def current_user
          context.current_user
        end

        def find_teacher
          context.teacher = User.joins(:roles).where(id: context.params[:id], roles: { key: 'teacher' }).first
          return if context.teacher

          context.message = ['Nauczyciel nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def update_teacher
          update_params = teacher_params.to_h
          merge_metadata(update_params)
          filter_blank_password(update_params)

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

        def filter_blank_password(update_params)
          return if update_params[:password].present?

          update_params.delete(:password)
          update_params.delete(:password_confirmation)
        end

        def teacher_params
          context.params.require(:teacher).permit(:first_name, :last_name, :email, :school_id, :password,
                                                  :password_confirmation, metadata: {})
        end
      end
    end
  end
end
