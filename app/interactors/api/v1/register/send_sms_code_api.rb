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
          # '%04d' % rand(0..9999)  # production
          '0000' # debug
        end

        def log_code
          Rails.logger.info "API SMS code for #{context.phone}: #{context.code}"
        end

        def send_sms
          # SmsGateway.send(context.phone, "Your verification code: #{context.code}")
        end
      end
    end
  end
end
