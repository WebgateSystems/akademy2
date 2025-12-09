module Users
  class SendSmsCode < BaseInteractor
    def call
      context.code = generate_code

      log_verification_code
      send_sms
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

    def send_sms
      TwilioService.send_sms(
        to: context.phone,
        body: "Your verification code: #{context.code}"
      )
    end
  end
end
