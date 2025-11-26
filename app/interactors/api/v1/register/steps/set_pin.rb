module Api
  module V1
    module Register
      module Steps
        class SetPin < BaseInteractor
          def call
            return flow_not_found unless flow
            return expired_flow if flow.expired?

            return invalid_form unless form.valid?

            save_temp_pin

            context.form = flow
            context.status = :ok
          end

          private

          def flow
            @flow ||= RegistrationFlow.find_by(id: context.params[:flow_id])
          end

          def form
            @form ||= Api::Register::PinForm.new(pin: context.params[:pin])
          end

          def invalid_form
            context.errors  = form.errors
            context.message = form.messages
            context.status  = :unprocessable_entity
            context.fail!
          end

          def flow_not_found
            context.message = ['Flow not found']
            context.status  = :not_found
            context.fail!
          end

          def expired_flow
            context.message = ['Flow expired']
            context.status  = :gone
            context.fail!
          end

          def save_temp_pin
            flow.update!(
              pin_temp: form.output[:pin],
              step: 'confirm_pin'
            )
          end
        end
      end
    end
  end
end
