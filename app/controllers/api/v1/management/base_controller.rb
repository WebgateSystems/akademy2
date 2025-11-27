# frozen_string_literal: true

module Api
  module V1
    module Management
      class BaseController < ApplicationApiController
        before_action :authorize_access_request!
        before_action :require_school_management_access!

        private

        def require_school_management_access!
          return unless current_user

          # Preload roles to avoid N+1 queries
          current_user.roles.load if current_user.roles.loaded? == false

          policy = SchoolManagementPolicy.new(current_user, :school_management)
          return if policy.access?

          render json: { error: 'Brak uprawnień' }, status: :forbidden
        end
      end
    end
  end
end
