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
      context.params.require(:register_profile_form).permit(
        :first_name,
        :last_name,
        :birthdate,
        :email,
        :phone
      )
    end

    def send_sms_code
      Register::SendSmsCode.call(phone: context.form.phone, flow: context.flow)
    end
  end
end
