module Register
  class SetPinConfirmSubmit < BaseInteractor
    def call
      valid_pin_and_match? ? process_success : fail_pin_mismatch
    end

    private

    def process_success
      save_pin_to_flow
      context.form = current_form

      save_user || fail_user_creation
    end

    def save_pin_to_flow
      context.flow.update(:pin, { 'pin' => current_form.pin })
    end

    def save_user
      user = build_user_from_flow

      return unless user.save

      context.flow.update(:user, { 'user_id' => user.id })
      user.send_confirmation_instructions
      true
    end

    def fail_user_creation
      context.redirect_path = redirect_to_profile
      context.fail!(message: build_user_from_flow.errors.full_messages.to_sentence)
    end

    def fail_pin_mismatch
      context.form = current_form
      context.fail!(message: 'Codes do not match')
    end

    def redirect_to_profile
      Rails.application.routes.url_helpers.register_profile_path
    end

    def valid_pin_and_match?
      current_form.valid? && current_form.pin == stored_pin
    end

    def current_form
      @current_form ||= PinForm.new(pin: submitted_pin)
    end

    def submitted_pin
      context.params[:pin_hidden]
    end

    def stored_pin
      context.flow['pin_temp']['pin']
    end

    def build_user_from_flow
      Register::BuildUserFromFlow.call(flow: context.flow).user
    end
  end
end
