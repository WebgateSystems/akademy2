# frozen_string_literal: true

module Api
  module V1
    module Management
      class CreateStudent < BaseInteractor
        CURRENT_ACADEMIC_YEAR = '2025/2026'

        def call
          authorize!
          build_student
          save_student
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

        def build_student
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          params_hash = student_params.to_h
          handle_metadata(params_hash)
          generate_password_if_needed(params_hash)
          # Force school_id to current user's school
          params_hash[:school_id] = school.id
          # Remove school_class_id as it's not a User attribute - it's handled separately
          params_hash.delete(:school_class_id)
          context.student = User.new(params_hash)
        end

        def handle_metadata(params_hash)
          if params_hash[:metadata].present?
            params_hash[:metadata] = params_hash[:metadata].symbolize_keys
          elsif get_param_value(:student, :metadata, :phone).present?
            params_hash[:metadata] = { phone: get_param_value(:student, :metadata, :phone) }
          end
        end

        def get_param_value(*keys)
          if context.params.is_a?(ActionController::Parameters)
            context.params.dig(*keys)
          else
            keys.inject(context.params) { |hash, key| hash&.dig(key) }
          end
        end

        def generate_password_if_needed(params_hash)
          return if params_hash[:password].present?

          random_password = SecureRandom.alphanumeric(16)
          params_hash[:password] = random_password
          params_hash[:password_confirmation] = random_password
        end

        def student_params
          # Convert to ActionController::Parameters if it's a hash
          params = if context.params.is_a?(ActionController::Parameters)
                     context.params
                   else
                     ActionController::Parameters.new(context.params)
                   end
          params.require(:student).permit(:first_name, :last_name, :email, :password,
                                          :password_confirmation, :school_class_id, metadata: {})
        end

        def save_student
          if context.student.save
            assign_student_role
            assign_to_class if get_param_value(:student, :school_class_id).present?
            # Create notification for awaiting approval
            NotificationService.create_student_awaiting_approval(student: context.student, school: school)
            context.form = context.student
            context.status = :created
            context.serializer = StudentSerializer
          else
            context.message = context.student.errors.full_messages
            context.fail!
          end
        end

        def assign_student_role
          student_role = Role.find_by(key: 'student')
          return unless student_role

          existing_role = UserRole.find_by(user: context.student, role: student_role, school: school)
          return if existing_role

          UserRole.create!(
            user: context.student,
            role: student_role,
            school: school
          )
        end

        def assign_to_class
          school_class_id = get_param_value(:student, :school_class_id)
          return unless school_class_id

          school_class = SchoolClass.find_by(id: school_class_id, school: school, year: CURRENT_ACADEMIC_YEAR)
          return unless school_class

          StudentClassEnrollment.find_or_create_by!(
            student: context.student,
            school_class: school_class
          )
        end
      end
    end
  end
end
