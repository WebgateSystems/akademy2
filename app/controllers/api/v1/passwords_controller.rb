# frozen_string_literal: true

module Api
  module V1
    class PasswordsController < ApplicationApiController
      # No authentication required for password reset
      skip_before_action :reject_blocked_request!, only: %i[forgot]

      def forgot
        result = Api::V1::Passwords::ForgotPassword.call(params:)
        default_handler(result)
      end
    end
  end
end
