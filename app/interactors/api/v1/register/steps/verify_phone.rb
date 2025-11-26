module Api
  module V1
    module Register
      module Steps
        class VerifyPhone < BaseInteractor
          def call
            return not_found unless flow
            return expired_flow if flow.expired?

            valid_code? ? good_outcome : bad_outcome
          end

          private

          def flow
            @flow ||= ::RegistrationFlow.find_by(id: context.params[:flow_id])
          end

          def submitted_code
            context.params[:code].to_s.strip
          end

          def valid_code?
            submitted_code.present? &&
              flow.phone_code.to_s == submitted_code
          end

          def good_outcome
            flow.update!(
              phone_verified: true,
              step: 'set_pin'
            )

            context.form = flow
            context.status = :ok
          end

          def bad_outcome
            context.status = :unprocessable_entity
            context.message = ['Invalid code']
            context.errors = [{ code: 'Invalid code' }]
            context.fail!
          end

          def expired_flow
            context.status = :gone
            context.message = ['Flow expired']
            context.fail!
          end
        end
      end
    end
  end
end
