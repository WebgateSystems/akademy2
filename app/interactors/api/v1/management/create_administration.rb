# frozen_string_literal: true

module Api
  module V1
    module Management
      class CreateAdministration < BaseInteractor
        def call
          authorize!
          build_administration
          save_administration
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

        def build_administration
          return context.fail!(message: ['Brak przypisanej szkoły']) unless school

          params_hash = administration_params.to_h
          handle_metadata(params_hash)
          generate_password_if_needed(params_hash)
          # Force school_id to current user's school
          params_hash[:school_id] = school.id
          # Remove roles from params_hash - they're assigned separately in assign_administration_roles
          params_hash.delete(:roles)
          context.administration = User.new(params_hash)
        end

        def handle_metadata(params_hash)
          if params_hash[:metadata].present?
            params_hash[:metadata] = params_hash[:metadata].symbolize_keys
          elsif context.params.dig(:administration, :metadata, :phone).present?
            params_hash[:metadata] = { phone: context.params.dig(:administration, :metadata, :phone) }
          end
        end

        def generate_password_if_needed(params_hash)
          return if params_hash[:password].present?

          random_password = SecureRandom.alphanumeric(16)
          params_hash[:password] = random_password
          params_hash[:password_confirmation] = random_password
        end

        def administration_params
          # Convert to ActionController::Parameters if it's a hash
          params = if context.params.is_a?(ActionController::Parameters)
                     context.params
                   else
                     ActionController::Parameters.new(context.params)
                   end
          params.require(:administration).permit(:first_name, :last_name, :email, :password,
                                                 :password_confirmation, metadata: {}, roles: [])
        end

        def save_administration
          if context.administration.save
            assign_administration_roles
            # Create notification for awaiting approval
            NotificationService.create_teacher_awaiting_approval(teacher: context.administration, school: school)
            context.form = context.administration
            context.status = :created
            context.serializer = AdministrationSerializer
          else
            context.message = context.administration.errors.full_messages
            context.fail!
          end
        end

        def assign_administration_roles
          roles_to_assign = context.params.dig(:administration, :roles) || []
          return if roles_to_assign.empty?

          roles_to_assign.each do |role_key|
            next unless %w[principal school_manager teacher].include?(role_key.to_s)

            role = Role.find_by(key: role_key.to_s)
            next unless role

            existing_role = UserRole.find_by(user: context.administration, role: role, school: school)
            next if existing_role

            UserRole.create!(
              user: context.administration,
              role: role,
              school: school
            )
          end
        end
      end
    end
  end
end
