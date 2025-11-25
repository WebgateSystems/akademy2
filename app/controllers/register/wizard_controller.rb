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
      result = Register::ProfileSubmit.call(params:, flow: @flow)
      @form = result.form

      return redirect_to register_verify_phone_path if result.success?

      render :profile, status: :unprocessable_entity
    end

    # === STEP 2: VERIFY PHONE ===

    def verify_phone
      @form = VerifyPhoneForm.new
      @phone = @flow['phone']['phone']
    end

    def resend_code
      phone = @flow.get(:phone)&.dig('phone')
      ::Register::SendSmsCode.call(phone:, flow: @flow)

      render json: { ok: true }
    end

    def verify_phone_submit
      result = Register::VerifyPhoneSubmit.call(params:, flow: @flow)

      @form  = result.form
      @phone = result.phone

      return redirect_to register_set_pin_path if result.success?

      flash.now[:alert] = result.error
      render :verify_phone, status: :unprocessable_entity
    end

    # === STEP 3: SET PIN ===

    def set_pin
      @form = PinForm.new
    end

    def set_pin_submit
      result = Register::SetPinSubmit.call(params:, flow: @flow)
      @form = result.form

      return redirect_to register_set_pin_confirm_path if result.success?

      render :set_pin, status: :unprocessable_entity
    end

    # === STEP 4: CONFIRM PIN ===

    def set_pin_confirm
      @form = PinForm.new
    end

    def set_pin_confirm_submit
      result = Register::SetPinConfirmSubmit.call(params:, flow: @flow)
      @form  = result.form

      result.success? ? handle_success : handle_failure(result)
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

    def ensure_step_allowed(step)
      redirect_to register_profile_path unless @flow.can_access?(step)
    end

    def handle_success
      redirect_to register_confirm_email_path
    end

    def handle_failure(result)
      flash[:alert] = result.message

      return redirect_to(result.redirect_path) if result.redirect_path.present?

      flash.now[:alert] = result.message
      render :set_pin_confirm, status: :unprocessable_entity
    end
  end
end
