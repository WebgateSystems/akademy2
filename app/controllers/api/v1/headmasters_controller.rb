module Api
  module V1
    class HeadmastersController < ApplicationApiController
      before_action :authorize_access_request!

      def index
        result = Api::V1::Headmasters::ListHeadmasters.call(params:, current_user:)
        default_handler(result)
      end

      def show
        result = Api::V1::Headmasters::ShowHeadmaster.call(params:, current_user:)
        default_handler(result)
      end

      def create
        result = Api::V1::Headmasters::CreateHeadmaster.call(params:, current_user:)
        default_handler(result)
      end

      def update
        result = Api::V1::Headmasters::UpdateHeadmaster.call(params:, current_user:)
        default_handler(result)
      end

      def destroy
        result = Api::V1::Headmasters::DestroyHeadmaster.call(params:, current_user:)
        default_handler(result)
      end

      def resend_invite
        result = Api::V1::Headmasters::ResendInviteHeadmaster.call(params:, current_user:)
        default_handler(result)
      end
    end
  end
end
