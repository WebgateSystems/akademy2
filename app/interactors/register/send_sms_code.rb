module Register
  class SendSmsCode < BaseInteractor
    def call
      context.code = generate_code

      context.flow.update(
        :phone,
        {
          'sms_code' => context.code,
          'verified' => false,
          'phone' => context.phone
        }
      )

      Rails.logger.info "SMS code for #{context.phone}: #{context.code}"

      # SmsGateway.send(context.phone, "Your code: #{context.code}")
    end

    private

    def generate_code
      # return '%04d' % rand(0..9999)   # ← включить в проде
      '0000' # ← DEBUG MODE
    end
  end
end
