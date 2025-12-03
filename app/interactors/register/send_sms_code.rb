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

      log_verification_code

      # SmsGateway.send(context.phone, "Your code: #{context.code}")
    end

    private

    def generate_code
      format('%04d', rand(0..9999))
    end

    def log_verification_code
      # rubocop:disable Rails/Output
      puts ''
      puts '=' * 60
      puts '📱 SMS VERIFICATION CODE'
      puts '=' * 60
      puts "   Phone: #{context.phone}"
      puts "   Code:  #{context.code}"
      puts '=' * 60
      puts ''
      # rubocop:enable Rails/Output

      Rails.logger.info "[SMS] Verification code for #{context.phone}: #{context.code}"
    end
  end
end
