# frozen_string_literal: true

module Api
  module V1
    module Management
      class AdministrationsController < Api::V1::Management::BaseController
        def index
          result = Api::V1::Management::ListAdministrations.call(params:, current_user:)
          default_handler(result)
        end

        def show
          result = Api::V1::Management::ShowAdministration.call(params:, current_user:)
          default_handler(result)
        end

        def create
          result = Api::V1::Management::CreateAdministration.call(params:, current_user:)
          default_handler(result)
        end

        def update
          result = Api::V1::Management::UpdateAdministration.call(params:, current_user:)
          default_handler(result)
        end

        def destroy
          result = Api::V1::Management::DestroyAdministration.call(params:, current_user:)
          default_handler(result)
        end

        def resend_invite
          result = Api::V1::Management::ResendInviteAdministration.call(params:, current_user:)
          default_handler(result)
        end

        def lock
          result = Api::V1::Management::LockAdministration.call(params:, current_user:)
          default_handler(result)
        end
      end
    end
  end
end
