module Register
  class SetPinSubmit < BaseInteractor
    def call
      current_form.valid? ? good_outcome : bad_outcome
    end

    private

    def good_outcome
      context.form = current_form

      context.flow.update(:pin_temp, { 'pin' => context.form.pin })
    end

    def bad_outcome
      context.form = current_form
      context.fail!(message: 'PIN validation failed')
    end

    def current_form
      @current_form ||= PinForm.new(pin: submitted_pin)
    end

    def submitted_pin
      context.params[:pin_hidden]
    end
  end
end
