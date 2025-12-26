# frozen_string_literal: true

module Api
  module V1
    module Student
      class AccountController < AuthentificateController
        before_action :require_student!

        JSON_VERIFY_RESPONSES = {
          ok: ->(c) { c.render json: { success: true, phone_verified: true } },
          invalid: lambda { |c|
            c.render json: { success: false, error: 'Invalid verification code' }, status: :unprocessable_entity
          },
          expired: lambda { |c|
            c.render json: { success: false, error: 'Verification code expired' }, status: :unprocessable_entity
          },
          fallback: lambda { |c|
            c.render json: { success: false, error: 'No verification request found' }, status: :unprocessable_entity
          }
        }.freeze

        HTML_VERIFY_RESPONSES = {
          ok: lambda { |c|
            c.redirect_back fallback_location: c.student_account_path, notice: 'Phone successfully verified.'
          },
          invalid: lambda { |c|
            c.redirect_back fallback_location: c.student_account_path, alert: 'Invalid verification code.'
          },
          expired: lambda { |c|
            c.redirect_back fallback_location: c.student_account_path, alert: 'Verification code expired.'
          },
          fallback: lambda { |c|
            c.redirect_back fallback_location: c.student_account_path, alert: 'No verification request found.'
          }
        }.freeze

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

        def verify_phone
          result = ::Users::SendSmsCode.call(
            phone: current_user.phone
          )

          update_phone_metadata!(current_user, result.code)

          render json: { success: true }
        end

        def verify_submit
          submitted_code = params.dig(:user, :verification_code).to_s.strip
          result = Users::VerifyPhoneCode.new(current_user, submitted_code).call

          return render_json_verify_response(result) if request.format.json?
          return render_html_verify_response(result) if request.format.html?

          render_json_verify_response(result)
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

        def update_phone_metadata!(user, code)
          user.metadata ||= {}

          user.metadata['phone_verification'] = {
            'code' => code,
            'phone' => user.phone,
            'sent_at' => Time.current.iso8601,
            'verified' => false,
            'attempts' => 0
          }

          user.save!
        end

        def render_json_verify_response(result)
          JSON_VERIFY_RESPONSES.fetch(result) { JSON_VERIFY_RESPONSES[:fallback] }.call(self)
        end

        def render_html_verify_response(result)
          HTML_VERIFY_RESPONSES.fetch(result) { HTML_VERIFY_RESPONSES[:fallback] }.call(self)
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
