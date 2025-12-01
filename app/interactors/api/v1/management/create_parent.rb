# frozen_string_literal: true

module Api
  module V1
    module Management
      class CreateParent < BaseInteractor
        def call
          authorize!
          build_parent
          save_parent
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

        def build_parent
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          params_hash = parent_params.to_h
          handle_metadata(params_hash)
          generate_password_if_needed(params_hash)
          params_hash[:school_id] = school.id
          params_hash[:confirmed_at] = Time.current # Parents are pre-approved
          params_hash.delete(:student_ids)
          params_hash.delete(:relation)
          context.parent = User.new(params_hash)
        end

        def handle_metadata(params_hash)
          if params_hash[:metadata].present?
            params_hash[:metadata] = params_hash[:metadata].symbolize_keys
          elsif params_hash[:phone].present?
            params_hash[:metadata] = { phone: params_hash[:phone] }
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

        def generate_password_if_needed(params_hash)
          return if params_hash[:password].present?

          random_password = SecureRandom.alphanumeric(16)
          params_hash[:password] = random_password
          params_hash[:password_confirmation] = random_password
        end

        def parent_params
          params = if context.params.is_a?(ActionController::Parameters)
                     context.params
                   else
                     ActionController::Parameters.new(context.params)
                   end

          # If params already has :parent key, use it; otherwise params are already permitted
          permitted_attrs = %i[first_name last_name email password password_confirmation phone relation]
          permitted = if params.key?(:parent)
                        params.require(:parent).permit(*permitted_attrs, metadata: {}, student_ids: [])
                      else
                        params.permit(*permitted_attrs, metadata: {}, student_ids: [])
                      end

          # Ensure student_ids is an array
          permitted[:student_ids] = Array(permitted[:student_ids]).reject(&:blank?) if permitted[:student_ids].present?
          permitted
        end

        def save_parent
          if context.parent.save
            assign_parent_role
            assign_students if get_param_value(:student_ids).present?
            context.form = context.parent
            context.status = :created
            context.serializer = ParentSerializer
            context.school_id = school.id
          else
            context.message = context.parent.errors.full_messages
            context.fail!
          end
        end

        def assign_parent_role
          parent_role = Role.find_by(key: 'parent')
          return unless parent_role

          existing_role = UserRole.find_by(user: context.parent, role: parent_role, school: school)
          return if existing_role

          UserRole.create!(
            user: context.parent,
            role: parent_role,
            school: school
          )
        end

        def assign_students
          student_ids = get_param_value(:student_ids)
          return unless student_ids.is_a?(Array)

          relation = get_param_value(:relation).presence || 'other'

          # Verify all students belong to this school
          students = User.joins(:user_roles)
                         .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                         .where(id: student_ids,
                                user_roles: { school_id: school.id },
                                roles: { key: 'student' })
                         .distinct

          students.each do |student|
            ParentStudentLink.find_or_create_by!(
              parent: context.parent,
              student: student,
              relation: relation
            )
          end
        end
      end
    end
  end
end
