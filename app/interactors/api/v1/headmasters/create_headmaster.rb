module Api
  module V1
    module Headmasters
      class CreateHeadmaster < BaseInteractor
        def call
          authorize!
          build_headmaster
          save_headmaster
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

        def build_headmaster
          params_hash = headmaster_params.to_h
          # Handle metadata - merge with existing if needed
          if params_hash[:metadata].present?
            params_hash[:metadata] = params_hash[:metadata].symbolize_keys
          elsif context.params.dig(:headmaster, :metadata, :phone).present?
            params_hash[:metadata] = { phone: context.params.dig(:headmaster, :metadata, :phone) }
          end
          # Generate random password if not provided
          unless params_hash[:password].present?
            random_password = SecureRandom.alphanumeric(16)
            params_hash[:password] = random_password
            params_hash[:password_confirmation] = random_password
          end
          context.headmaster = User.new(params_hash)
        end

        def headmaster_params
          context.params.require(:headmaster).permit(:first_name, :last_name, :email, :school_id, :password,
                                                     :password_confirmation, metadata: {})
        end

        def save_headmaster
          if context.headmaster.save
            # Assign principal role
            principal_role = Role.find_by(key: 'principal')
            if principal_role
              UserRole.create!(user: context.headmaster, role: principal_role, school: context.headmaster.school)
            end
            context.form = context.headmaster
            context.status = :created
            context.serializer = HeadmasterSerializer
          else
            context.message = context.headmaster.errors.full_messages
            context.fail!
          end
        end
      end
    end
  end
end
