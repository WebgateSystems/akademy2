module Api
  module V1
    module Headmasters
      class UpdateHeadmaster < BaseInteractor
        def call
          authorize!
          find_headmaster
          update_headmaster
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

        def find_headmaster
          context.headmaster = User.joins(:roles).where(id: context.params[:id], roles: { key: 'principal' }).first
          return if context.headmaster

          context.message = ['Dyrektor nie został znaleziony']
          context.status = :not_found
          context.fail!
        end

        def update_headmaster
          update_params = headmaster_params.to_h

          # Handle metadata - merge with existing metadata
          if update_params[:metadata].present?
            current_metadata = context.headmaster.metadata || {}
            update_params[:metadata] = current_metadata.deep_merge(update_params[:metadata].symbolize_keys)
          elsif context.params.dig(:headmaster, :metadata, :phone).present?
            current_metadata = context.headmaster.metadata || {}
            update_params[:metadata] = current_metadata.merge(phone: context.params.dig(:headmaster, :metadata, :phone))
          end

          if context.headmaster.update(update_params)
            context.form = context.headmaster
            context.status = :ok
            context.serializer = HeadmasterSerializer
          else
            context.message = context.headmaster.errors.full_messages
            context.fail!
          end
        end

        def headmaster_params
          context.params.require(:headmaster).permit(:first_name, :last_name, :email, :school_id, :password,
                                                     :password_confirmation, metadata: {})
        end
      end
    end
  end
end
