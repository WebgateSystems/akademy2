# frozen_string_literal: true

module Api
  module V1
    module Passwords
      class ResetPassword < BaseInteractor
        def call
          return invalid_params unless valid_params?

          reset_user_password
          return handle_errors unless user
          return user_blocked unless user_allowed?
          return handle_validation_errors if user.errors.any?

          success
        end

        private

        def valid_params?
          reset_token.present? && password.present? && password_confirmation.present?
        end

        def reset_token
          @reset_token ||= context.params[:reset_password_token] || context.params.dig(:user, :reset_password_token)
        end

        def password
          @password ||= context.params[:password] || context.params.dig(:user, :password)
        end

        def password_confirmation
          @password_confirmation ||= context.params[:password_confirmation] ||
                                     context.params.dig(:user, :password_confirmation)
        end

        def reset_user_password
          # Devise's reset_password_by_token:
          # - Finds user by token
          # - Validates token hasn't expired (based on reset_password_within config)
          # - Updates password if valid
          # - Returns user with errors if token invalid/expired or password validation fails
          # - Returns nil if user not found
          @user = User.reset_password_by_token(
            reset_password_token: reset_token,
            password: password,
            password_confirmation: password_confirmation
          )
        end

        attr_reader :user

        def invalid_params
          context.status = :unprocessable_entity
          context.fail!(message: ['Reset token, password and password confirmation are required'])
        end

        def handle_errors
          # User is nil - token invalid or user not found
          context.status = :unprocessable_entity
          context.fail!(message: ['Invalid or expired reset token'])
        end

        def handle_validation_errors
          # Check if it's a token error or password validation error
          context.status = :unprocessable_entity
          if user.errors[:reset_password_token].any?
            context.fail!(message: ['Invalid or expired reset token'])
          else
            # Password validation errors (length, confirmation mismatch, etc.)
            context.fail!(message: user.errors.full_messages)
          end
        end

        def user_allowed?
          return true unless user

          user.active? && !RequestBlockRule.blocked?(user_id: user.id)
        end

        def user_blocked
          context.status = :forbidden
          context.fail!(message: ['User account is blocked'])
        end

        def success
          context.status = :ok
          context.form = { message: I18n.t('devise.passwords.updated_not_active') }
        end
      end
    end
  end
end
