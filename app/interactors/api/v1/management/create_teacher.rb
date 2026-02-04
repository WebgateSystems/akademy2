# frozen_string_literal: true

module Api
  module V1
    module Management
      class CreateTeacher < BaseInteractor
        def call
          authorize!
          build_teacher
          save_teacher
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

        def build_teacher
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          params_hash = teacher_params.to_h
          handle_metadata(params_hash)
          generate_password_if_needed(params_hash)
          # Force school_id to current user's school
          params_hash[:school_id] = school.id
          context.teacher = User.new(params_hash)
        end

        def handle_metadata(params_hash)
          return params_hash[:metadata] = params_hash[:metadata].symbolize_keys if params_hash[:metadata].present?

          phone = context.params.dig(:teacher, :metadata, :phone)
          params_hash[:metadata] = { phone: phone } if phone.present?
        end

        def generate_password_if_needed(params_hash)
          return if params_hash[:password].present?

          params_hash[:password] = params_hash[:password_confirmation] = SecureRandom.alphanumeric(16)
        end

        def teacher_params
          params = context.params.is_a?(ActionController::Parameters) ? context.params : ActionController::Parameters.new(context.params)
          params.require(:teacher).permit(:first_name, :last_name, :email, :password, :password_confirmation,
                                          metadata: {})
        end

        def save_teacher
          context.teacher.skip_confirmation!

          if context.teacher.save
            assign_teacher_role
            assign_school_manager_role_if_requested
            create_approved_enrollment
            context.form = context.teacher
            context.status = :created
            context.serializer = TeacherSerializer
            send_reset_instruction
          else
            context.message = context.teacher.errors.full_messages
            context.fail!
          end
        end

        def assign_teacher_role
          assign_role('teacher')
        end

        def assign_school_manager_role_if_requested
          return unless context.params.dig(:teacher, :is_school_manager) == true

          assign_role('school_manager')
        end

        def assign_role(role_key)
          role = Role.find_by(key: role_key)
          return unless role && school

          UserRole.find_or_create_by!(user: context.teacher, role: role, school: school)
        end

        def create_approved_enrollment
          # Teacher added manually by management is automatically approved
          TeacherSchoolEnrollment.find_or_create_by!(
            teacher: context.teacher,
            school: school
          ) do |enrollment|
            enrollment.status = 'approved'
            enrollment.joined_at = Time.current
          end
        end

        def send_reset_instruction
          context.teacher.send_reset_password_instructions
        end
      end
    end
  end
end
