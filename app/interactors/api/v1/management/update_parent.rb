# frozen_string_literal: true

module Api
  module V1
    module Management
      class UpdateParent < BaseInteractor
        def call
          authorize!
          find_parent
          update_parent
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

        def find_parent
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          context.parent = User.joins(:user_roles)
                               .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                               .where(id: context.params[:id],
                                      user_roles: { school_id: school.id },
                                      roles: { key: 'parent' })
                               .distinct
                               .first

          return if context.parent

          context.message = ['Rodzic nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def update_parent
          update_params = prepare_update_params
          return unless update_params

          if context.parent.update(update_params)
            update_students if get_param_value(:student_ids).present?
            handle_email_change(update_params)
            set_success_response
          else
            context.message = context.parent.errors.full_messages
            context.fail!
          end
        end

        def prepare_update_params
          update_params = parent_params.to_h
          merge_metadata(update_params)
          update_params[:school_id] = school.id
          update_params.delete(:student_ids)
          update_params.delete(:relation)
          update_params
        end

        def merge_metadata(update_params)
          return if update_params[:metadata].blank?

          existing_metadata = context.parent.metadata || {}
          update_params[:metadata] = existing_metadata.deep_merge(update_params[:metadata].symbolize_keys)
        end

        def handle_email_change(update_params)
          return unless update_params[:email].present? && context.parent.email != update_params[:email]

          context.parent.skip_reconfirmation!
        end

        def update_students
          student_ids = get_param_value(:student_ids)
          return unless student_ids.is_a?(Array)

          relation = get_param_value(:relation).presence || 'other'

          # Remove existing links
          context.parent.parent_student_links.destroy_all

          # Add new links
          students = User.joins(:user_roles)
                         .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                         .where(id: student_ids,
                                user_roles: { school_id: school.id },
                                roles: { key: 'student' })
                         .distinct

          students.each do |student|
            ParentStudentLink.create!(
              parent: context.parent,
              student: student,
              relation: relation
            )
          end
        end

        def get_param_value(*keys)
          if context.params.is_a?(ActionController::Parameters)
            # Try with :parent key first, then without
            value = context.params.dig(:parent, *keys)
            return value if value.present? || context.params.key?(:parent)

            context.params.dig(*keys)
          else
            # Try with :parent key first, then without
            value = keys.inject(context.params) { |hash, key| hash&.dig(:parent, key) }
            return value if value.present? || context.params.key?(:parent)

            keys.inject(context.params) { |hash, key| hash&.dig(key) }
          end
        end

        def parent_params
          params = if context.params.is_a?(ActionController::Parameters)
                     context.params
                   else
                     ActionController::Parameters.new(context.params)
                   end

          # If params already has :parent key, use it; otherwise params are already permitted
          if params.key?(:parent)
            permitted = params.require(:parent).permit(:first_name, :last_name, :email, :phone, :relation,
                                                       metadata: {}, student_ids: [])
          else
            # Params are already permitted from controller, :id is passed separately for find_parent
            permitted = params.permit(:id, :first_name, :last_name, :email, :phone, :relation, metadata: {},
                                                                                               student_ids: [])
          end

          # Ensure student_ids is an array
          permitted[:student_ids] = Array(permitted[:student_ids]).reject(&:blank?) if permitted[:student_ids].present?
          permitted
        end

        def set_success_response
          context.form = context.parent.reload
          context.status = :ok
          context.serializer = ParentSerializer
          context.school_id = school.id
        end
      end
    end
  end
end
