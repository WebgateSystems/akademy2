# frozen_string_literal: true

module Api
  module V1
    module Students
      class CreateStudent < BaseInteractor
        def call
          authorize!
          build_student
          save_student
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

        def build_student
          params_hash = student_params.to_h
          handle_metadata(params_hash)
          generate_password_if_needed(params_hash)
          context.student = User.new(params_hash)
        end

        def handle_metadata(params_hash)
          if params_hash[:metadata].present?
            params_hash[:metadata] = params_hash[:metadata].symbolize_keys
            # Extract birth_date from metadata and save to birthdate field
            if params_hash[:metadata][:birth_date].present? && params_hash[:birthdate].blank?
              params_hash[:birthdate] = params_hash[:metadata][:birth_date]
            end
          elsif context.params.dig(:student, :metadata, :phone).present?
            params_hash[:metadata] = { phone: context.params.dig(:student, :metadata, :phone) }
          end
        end

        def generate_password_if_needed(params_hash)
          return if params_hash[:password].present?

          random_password = SecureRandom.alphanumeric(16)
          params_hash[:password] = random_password
          params_hash[:password_confirmation] = random_password
        end

        def student_params
          context.params.require(:student).permit(:first_name, :last_name, :email, :school_id, :password,
                                                  :password_confirmation, :birthdate, metadata: {})
        end

        def save_student
          if context.student.save
            assign_student_role
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

          school = context.student.school
          return unless school

          existing_role = UserRole.find_by(user: context.student, role: student_role, school: school)
          return if existing_role

          UserRole.create!(
            user: context.student,
            role: student_role,
            school: school
          )
        end
      end
    end
  end
end
