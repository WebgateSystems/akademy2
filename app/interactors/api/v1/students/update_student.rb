# frozen_string_literal: true

module Api
  module V1
    module Students
      class UpdateStudent < BaseInteractor
        def call
          authorize!
          find_student
          update_student
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

        def find_student
          context.student = User.joins(:roles).where(id: context.params[:id], roles: { key: 'student' }).first
          return if context.student

          context.message = ['Uczeń nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def update_student
          update_params = student_params.to_h
          merge_metadata(update_params)

          # Skip Devise confirmation email when updating email (admin action)
          email_changed = update_params[:email].present? && context.student.email != update_params[:email]
          context.student.skip_reconfirmation! if email_changed

          if context.student.update(update_params)
            context.form = context.student
            context.status = :ok
            context.serializer = StudentSerializer
          else
            context.message = context.student.errors.full_messages
            context.fail!
          end
        end

        def merge_metadata(update_params)
          if update_params[:metadata].present?
            current_metadata = context.student.metadata || {}
            update_params[:metadata] = current_metadata.deep_merge(update_params[:metadata].symbolize_keys)
            # Extract birth_date from metadata and save to birthdate field
            if update_params[:metadata][:birth_date].present? && update_params[:birthdate].blank?
              update_params[:birthdate] = update_params[:metadata][:birth_date]
            end
          elsif context.params.dig(:student, :metadata, :phone).present?
            current_metadata = context.student.metadata || {}
            update_params[:metadata] = current_metadata.merge(
              phone: context.params.dig(:student, :metadata, :phone)
            )
          end
        end

        def student_params
          context.params.require(:student).permit(:first_name, :last_name, :email, :school_id, :password,
                                                  :password_confirmation, :birthdate, metadata: {})
        end
      end
    end
  end
end
