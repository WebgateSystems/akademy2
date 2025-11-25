module Register
  class VerifyPhoneSubmit < BaseInteractor
    def call
      valid_code? ? good_outcome : bad_outcome
    end

    private

    def good_outcome
      context.form = current_form

      context.flow.update(:phone, { 'verified' => true })
    end

    def bad_outcome
      context.form = current_form
      context.phone = context.flow['profile']['phone']
      context.error = 'Wrong Code'
      context.fail!(message: 'Wrong Code')
    end

    def current_form
      @current_form ||= VerifyPhoneForm.new(code: submitted_code)
    end

    def submitted_code
      [
        context.params[:code1],
        context.params[:code2],
        context.params[:code3],
        context.params[:code4]
      ].join
    end

    def valid_code?
      current_form.valid? &&
        submitted_code == context.flow['phone']['sms_code']
    end
  end
end
