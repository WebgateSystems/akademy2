# frozen_string_literal: true

module Api
  module V1
    module Teachers
      class CreateTeacher < BaseInteractor
        def call
          authorize!
          build_teacher
          save_teacher
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

        def build_teacher
          params_hash = teacher_params.to_h
          handle_metadata(params_hash)
          generate_password_if_needed(params_hash)
          context.teacher = User.new(params_hash)
        end

        def handle_metadata(params_hash)
          if params_hash[:metadata].present?
            params_hash[:metadata] = params_hash[:metadata].symbolize_keys
          elsif context.params.dig(:teacher, :metadata, :phone).present?
            params_hash[:metadata] = { phone: context.params.dig(:teacher, :metadata, :phone) }
          end
        end

        def generate_password_if_needed(params_hash)
          return if params_hash[:password].present?

          random_password = SecureRandom.alphanumeric(16)
          params_hash[:password] = random_password
          params_hash[:password_confirmation] = random_password
        end

        def teacher_params
          context.params.require(:teacher).permit(:first_name, :last_name, :email, :school_id, :password,
                                                  :password_confirmation, metadata: {})
        end

        def save_teacher
          if context.teacher.save
            # Assign teacher role immediately after save
            assign_teacher_role
            context.form = context.teacher
            context.status = :created
            context.serializer = TeacherSerializer
          else
            context.message = context.teacher.errors.full_messages
            context.fail!
          end
        end

        # rubocop:disable Metrics/MethodLength
        def assign_teacher_role
          teacher_role = Role.find_by(key: 'teacher')
          return unless teacher_role

          school = context.teacher.school
          return unless school

          existing_role = UserRole.find_by(user: context.teacher, role: teacher_role, school: school)
          return if existing_role

          UserRole.create!(
            user: context.teacher,
            role: teacher_role,
            school: school
          )
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
