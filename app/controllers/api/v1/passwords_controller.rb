# frozen_string_literal: true

module Api
  module V1
    class PasswordsController < ApplicationApiController
      # No authentication required for password reset
      skip_before_action :reject_blocked_request!, only: %i[forgot reset]

      def forgot
        result = Api::V1::Passwords::ForgotPassword.call(params:)
        default_handler(result)
      end

      def reset
        # REMOVE THIS AFTER TESTING
        # result = Api::V1::Passwords::ResetPassword.call(params:)
        # default_handler(result)
        render json: { message: 'Reset password' }, status: :no_content
      end
    end
  end
end
