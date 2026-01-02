# frozen_string_literal: true

module Api
  module V1
    module Passwords
      class ForgotPassword < BaseInteractor
        def call
          return invalid_email unless email_present?
          return user_not_found unless user
          return user_blocked unless user_allowed?

          send_reset_instructions
          success
        end

        private

        def email_present?
          email.present?
        end

        def email
          @email ||= context.params[:email] || context.params.dig(:user, :email)
        end

        def user
          @user ||= User.find_by(email: email&.downcase&.strip)
        end

        def invalid_email
          context.status = :unprocessable_entity
          context.fail!(message: ['Email is required'])
        end

        def user_not_found
          # For security, don't reveal if user exists or not
          # Always return success message
          context.status = :ok
          context.form = { message: I18n.t('devise.passwords.send_paranoid_instructions') }
        end

        def user_allowed?
          return true unless user

          user.active? && !RequestBlockRule.blocked?(user_id: user.id)
        end

        def user_blocked
          context.status = :ok
          context.form = { message: I18n.t('devise.passwords.send_paranoid_instructions') }
        end

        def send_reset_instructions
          user.send_reset_password_instructions
        end

        def success
          context.status = :ok
          context.form = { message: I18n.t('devise.passwords.send_paranoid_instructions') }
        end
      end
    end
  end
end
