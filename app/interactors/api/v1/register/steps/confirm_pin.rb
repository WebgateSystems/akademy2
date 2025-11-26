module Api
  module V1
    module Register
      module Steps
        class ConfirmPin < BaseInteractor
          def call
            return not_found unless flow
            return bad_outcome unless current_form.valid?
            return mismatch unless pins_match?

            run_finish_step
          end

          private

          def current_form
            @current_form ||= Api::Register::PinForm.new(pin: submitted_pin)
          end

          def submitted_pin
            context.params[:pin]
          end

          def flow
            @flow ||= RegistrationFlow.find_by(id: context.params[:flow_id])
          end

          def pins_match?
            submitted_pin == flow.pin_temp
          end

          def bad_outcome
            context.errors = form.errors
            context.message = form.error_messages
            context.fail!
          end

          def mismatch
            context.message = ['Codes do not match']
            context.errors = [{ code: 'Codes do not match' }]
            context.status = :unprocessable_entity
            context.fail!
          end

          def run_finish_step
            @finish_result = Api::V1::Register::Steps::Finish.call(params: { flow_id: flow })

            @finish_result.success? ? good_filish_outcome : bad_finish_outcome
          end

          def good_filish_outcome
            context.form = @finish_result.form
            context.access_token = @finish_result.access_token
            context.status = :created
          end

          def bad_finish_outcome
            context.message = @finish_result.message
            context.status = :unprocessable_entity
            context.fail!
          end
        end
      end
    end
  end
end
