# frozen_string_literal: true

module Register
  class WizardController < ApplicationController
    layout "register"

    before_action :build_flow
    before_action :ensure_profile_completed, only: %i[verify_phone verify_phone_submit set_pin set_pin_submit confirm_email]
    before_action :ensure_phone_verified,    only: %i[set_pin set_pin_submit confirm_email]

    # === STEP 1: PROFILE ===

    def profile
      @form = ProfileForm.new(@flow["profile"] || {})
    end

    def profile_submit
      @form = ProfileForm.new(profile_params)

      if @form.valid?
        @flow.update(:profile, @form.to_h)
        send_sms_code(@form.phone)
        redirect_to register_verify_phone_path
      else
        render :profile, status: :unprocessable_entity
      end
    end

    # === STEP 2: VERIFY PHONE ===

    def verify_phone
      @form = VerifyPhoneForm.new
      @phone = @flow["profile"]["phone"]
    end

    def verify_phone_submit
      code = merge_code(params[:code1], params[:code2], params[:code3], params[:code4])
      @form = VerifyPhoneForm.new(code: code)

      if @form.valid? && code == @flow.phone["sms_code"]
        @flow.update(:phone, { "verified" => true })
        redirect_to register_set_pin_path
      else
        @phone = @flow["profile"]["phone"]
        flash.now[:alert] = "Wrong Code"
        render :verify_phone, status: :unprocessable_entity
      end
    end

    # === STEP 3: SET PIN ===

    def set_pin
      @form = PinForm.new
    end

    def set_pin_submit
      pin = merge_code(params[:pin1], params[:pin2], params[:pin3], params[:pin4])
      @form = PinForm.new(pin: pin)

      if @form.valid?
        @flow.update(:pin, { "pin" => pin })

        user = build_user_from_flow
        flash[:success] = 'Reg'
        redirect_to register_confirm_email_path

        # if user.save
        #   @flow.update(:user, { "user_id" => user.id })
        #   user.send_confirmation_instructions
        #   redirect_to register_confirm_email_path
        # else
        #   # если Devise-валидации не прошли, откатываемся на профиль
        #   flash[:alert] = user.errors.full_messages.to_sentence
        #   redirect_to register_profile_path
        # end
      else
        render :set_pin, status: :unprocessable_entity
      end
    end

    # === STEP 4: CONFIRM EMAIL SCREEN ===

    def confirm_email
      profile = @flow["profile"] || {}
      @user_email = profile["email"]
      # when clear session @flow.clear!
    end

    private

    def build_flow
      @flow = WizardFlow.new(session)
    end

    def profile_params
      params.permit(:first_name, :last_name, :birthdate, :email, :phone, :marketing)
    end

    def merge_code(*digits)
      digits.join
    end

    def send_sms_code(phone)
      # code = "%04d" % rand(0..9999)
      code = '0000'
      @flow.update(:phone, { "sms_code" => code, "verified" => false, "phone" => phone })

      # Here (Twilio, SMSAPI, etc.)
      # SmsSender.call(phone, "Your code: #{code}")
      Rails.logger.info "SMS code for #{phone}: #{code}"
    end

    def build_user_from_flow
      profile = @flow["profile"] || {}
      pin     = @flow["pin"]["pin"]

      User.new(
        first_name: profile["first_name"],
        last_name:  profile["last_name"],
        email:      profile["email"],
      #   phone:      profile["phone"],
        password:   pin,
        # password_confirmation: pin,
      #   marketing:  profile["marketing"]
      )
      # User need add phone birthday marketing(checkbox in first form)
    end

    # --- guards ---

    def ensure_profile_completed
      return if @flow.profile_completed?

      redirect_to register_profile_path
    end

    def ensure_phone_verified
      return if @flow.phone_verified?

      redirect_to register_verify_phone_path
    end
  end
end
