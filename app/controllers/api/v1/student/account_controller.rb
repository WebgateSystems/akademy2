# frozen_string_literal: true

module Api
  module V1
    module Student
      class AccountController < ApplicationApiController
        before_action :authorize_access_request!
        before_action :require_student!

        # GET /api/v1/student/account
        def show
          render json: {
            success: true,
            data: account_data
          }
        end

        # PATCH /api/v1/student/account
        def update
          user = current_user
          errors = []

          # Check if email can be changed
          if account_params[:email].present? && account_params[:email] != user.email
            if user.confirmed_at.present?
              errors << I18n.t('api.student.account.email_verified_cannot_change')
            else
              # Skip reconfirmation for unverified users
              user.skip_reconfirmation!
              user.email = account_params[:email]
            end
          end

          # Check if phone can be changed
          if account_params[:phone].present? && account_params[:phone] != user.phone
            if user.metadata&.dig('phone_verified')
              errors << I18n.t('api.student.account.phone_verified_cannot_change')
            else
              user.phone = account_params[:phone]
            end
          end

          if errors.any?
            render json: { success: false, errors: errors }, status: :unprocessable_entity
          elsif user.save
            render json: { success: true, data: account_data, message: I18n.t('api.student.account.updated') }
          else
            render json: { success: false, errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/student/account/settings
        def settings
          render json: {
            success: true,
            data: settings_data
          }
        end

        # PATCH /api/v1/student/account/settings
        def update_settings
          user = current_user
          errors = []

          # Handle PIN change
          if settings_params[:new_pin].present?
            new_pin = settings_params[:new_pin]
            pin_confirmation = settings_params[:pin_confirmation]

            if new_pin.length != 4
              errors << I18n.t('student_dashboard.settings.pin_length_error')
            elsif !new_pin.match?(/^\d{4}$/)
              errors << I18n.t('student_dashboard.settings.pin_digits_only')
            elsif new_pin != pin_confirmation
              errors << I18n.t('student_dashboard.settings.pin_mismatch')
            else
              user.password = new_pin
              user.password_confirmation = pin_confirmation
            end
          end

          user.locale = settings_params[:locale] if settings_params[:locale].present?
          user.theme = settings_params[:theme] if settings_params[:theme].present?

          if errors.any?
            render json: { success: false, errors: errors }, status: :unprocessable_entity
          elsif user.save
            render json: { success: true, data: settings_data, message: I18n.t('student_dashboard.settings.updated') }
          else
            render json: { success: false, errors: user.errors.full_messages }, status: :unprocessable_entity
          end
        end

        # POST /api/v1/student/account/request_deletion
        def request_deletion
          NotificationService.create_account_deletion_request(
            student: current_user,
            school: current_user.school
          )

          render json: {
            success: true,
            message: I18n.t('student_dashboard.account.deletion_requested')
          }
        end

        private

        def require_student!
          return if current_user.student?

          render json: { success: false, error: 'Student access required' }, status: :forbidden
        end

        def account_params
          params.require(:account).permit(:email, :phone)
        end

        def settings_params
          params.require(:settings).permit(:locale, :theme, :new_pin, :pin_confirmation)
        end

        def account_data
          user = current_user
          {
            id: user.id,
            full_name: user.full_name,
            first_name: user.first_name,
            last_name: user.last_name,
            email: user.email,
            email_verified: user.confirmed_at.present?,
            phone: user.display_phone,
            phone_verified: user.metadata&.dig('phone_verified') || false,
            birthdate: user.birthdate&.strftime('%Y-%m-%d'),
            can_edit_email: user.confirmed_at.blank?,
            can_edit_phone: !user.metadata&.dig('phone_verified')
          }
        end

        def settings_data
          user = current_user
          {
            locale: user.locale || 'en',
            theme: user.theme || 'light',
            available_locales: %w[en pl],
            available_themes: %w[light dark]
          }
        end
      end
    end
  end
end
