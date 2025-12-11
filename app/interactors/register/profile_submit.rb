module Register
  class ProfileSubmit < BaseInteractor
    def call
      current_form.valid? ? good_outcome : bad_outcome
    end

    private

    def good_outcome
      context.form = current_form
      context.flow.update(:profile, context.form.to_h)
      send_sms_code
    end

    def bad_outcome
      context.fail!(message: 'Validation failed')
    end

    def current_form
      @current_form ||= ::Register::ProfileForm.new(permit_params)
    end

    def permit_params
      # birthdate_display and marketing are only for form display, not stored in form model
      permitted = context.params.require(:register_profile_form).permit(
        :first_name,
        :last_name,
        :birthdate,
        :birthdate_display,
        :email,
        :phone,
        :marketing
      )
      # Remove fields that are not part of the form model
      permitted.except(:birthdate_display, :marketing)
    end

    def send_sms_code
      Register::SendSmsCode.call(phone: context.form.phone, flow: context.flow)
    end
  end
end
