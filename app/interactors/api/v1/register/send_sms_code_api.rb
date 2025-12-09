module Api
  module V1
    module Register
      class SendSmsCodeApi < BaseInteractor
        def call
          return invalid_flow unless flow

          context.code = generate_code
          update_flow!
          log_code
          send_sms
        end

        private

        def flow
          context.flow
        end

        def invalid_flow
          context.fail!(message: ['Flow not found'], status: :not_found)
        end

        def update_flow!
          update_phone_data
          update_step
          persist_flow
        end

        def update_phone_data
          flow.phone_code = context.code
          flow.phone_verified = false

          flow.data ||= {}
          flow.data['phone'] = {
            'number' => context.phone
          }
        end

        def update_step
          flow.step = 'verify_phone'
        end

        def persist_flow
          flow.save!
        end

        def generate_code
          format('%04d', rand(0..9999))
        end

        def log_code
          # rubocop:disable Rails/Output
          puts ''
          puts '=' * 60
          puts '📱 SMS VERIFICATION CODE (API)'
          puts '=' * 60
          puts "   Phone: #{context.phone}"
          puts "   Code:  #{context.code}"
          puts '=' * 60
          puts ''
          # rubocop:enable Rails/Output

          Rails.logger.info "[SMS API] Verification code for #{context.phone}: #{context.code}"
        end

        def send_sms
          ::TwilioService.send_sms(
            to: context.phone,
            body: "Your verification code: #{context.code}"
          )
        end
      end
    end
  end
end
