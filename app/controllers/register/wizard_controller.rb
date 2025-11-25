module Register
  class WizardController < ApplicationController
    layout 'register'

    before_action :build_flow

    before_action -> { ensure_step_allowed(:verify_phone) }, only: %i[verify_phone verify_phone_submit]
    before_action -> { ensure_step_allowed(:set_pin) }, only: %i[set_pin set_pin_submit]
    before_action -> { ensure_step_allowed(:set_pin_confirm) }, only: %i[set_pin_confirm set_pin_confirm_submit]
    before_action -> { ensure_step_allowed(:confirm_email) }, only: [:confirm_email]

    # === STEP 1: PROFILE ===

    def profile
      @form = ProfileForm.new(@flow['profile'] || {})
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
      @phone = @flow['phone']['phone']
    end

    def resend_code
      phone = @flow.get(:phone)&.dig('phone')
      send_sms_code(phone)
      render json: { ok: true }
    end

    def verify_phone_submit
      code = merge_code(params[:code1], params[:code2], params[:code3], params[:code4])
      @form = VerifyPhoneForm.new(code: code)

      if @form.valid? && code == @flow['phone']['sms_code']
        @flow.update(:phone, { 'verified' => true })
        redirect_to register_set_pin_path
      else
        @phone = @flow['profile']['phone']
        flash.now[:alert] = 'Wrong Code'
        render :verify_phone, status: :unprocessable_entity
      end
    end

    # === STEP 3: SET PIN ===

    def set_pin
      @form = PinForm.new
    end

    def set_pin_submit
      pin = params[:pin_hidden]
      @form = PinForm.new(pin: pin)

      if @form.valid?
        @flow.update(:pin_temp, { 'pin' => pin })
        redirect_to register_set_pin_confirm_path
      else
        render :set_pin, status: :unprocessable_entity
      end
    end

    # === STEP 4: CONFIRM PIN ===

    def set_pin_confirm
      @form = PinForm.new
    end

    def set_pin_confirm_submit
      confirm_pin = params[:pin_hidden]
      @form = PinForm.new(pin: confirm_pin)

      stored_pin = @flow['pin_temp']['pin']

      if @form.valid? && confirm_pin == stored_pin
        @flow.update(:pin, { 'pin' => confirm_pin })

        user = build_user_from_flow

        if user.save
          @flow.update(:user, { 'user_id' => user.id })
          user.send_confirmation_instructions
          redirect_to register_confirm_email_path
        else
          flash[:alert] = user.errors.full_messages.to_sentence
          redirect_to register_profile_path
        end

      else
        flash.now[:alert] = 'Codes do not match'
        render :set_pin_confirm, status: :unprocessable_entity
      end
    end

    # === STEP 5: CONFIRM EMAIL SCREEN ===

    def confirm_email
      user_id = @flow['user']&.dig('user_id')
      @user = User.find_by(id: user_id)
      sign_in(@user) if @user

      @user_email = @user&.email
      @flow.finish!
    end

    private

    def build_flow
      @flow = WizardFlow.new(session)
    end

    def profile_params
      params.require(:register_profile_form).permit(:first_name, :last_name, :birthdate, :email, :phone)
    end

    def merge_code(*digits)
      digits.join
    end

    def send_sms_code(phone)
      # code = '%04d' % rand(0..9999)
      code = '0000' # for debug

      @flow.update(:phone, { 'sms_code' => code, 'verified' => false, 'phone' => phone })
      Rails.logger.info "SMS code for #{phone}: #{code}"
    end

    def build_user_from_flow
      profile = @flow['profile'] || {}
      pin     = @flow['pin']['pin']

      User.new(
        first_name: profile['first_name'],
        last_name: profile['last_name'],
        email: profile['email'],
        phone: profile['phone'],
        birthdate: profile['birthdate'],
        password: pin,
        password_confirmation: pin
      )
    end

    def ensure_step_allowed(step)
      redirect_to register_profile_path unless @flow.can_access?(step)
    end
  end
end
