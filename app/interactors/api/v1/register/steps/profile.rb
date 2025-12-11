module Api
  module V1
    module Register
      module Steps
        class Profile < BaseInteractor
          def call
            return not_found unless flow
            return bad_outcome unless form.valid?

            update_flow
            send_sms_code

            context.form = flow
            context.status = :ok
          end

          private

          def form
            @form ||= Api::Register::ProfileForm.new(permit_params)
          end

          def current_form
            form
          end

          def permit_params
            context.params.require(:profile).permit(:first_name, :last_name, :email, :birthdate, :phone).to_h
          end

          def flow
            @flow ||= ::RegistrationFlow.find_by(id: context.params[:flow_id])
          end

          def update_flow
            flow.data ||= {}
            flow.data['profile'] = form.output

            store_class_token_in_flow if class_token_present?

            flow.step = 'verify_phone'
            flow.expires_at = 30.minutes.from_now
            flow.save!
          end

          def class_token_present?
            (context.params[:class_token] || context.params[:join_token]).present?
          end

          def store_class_token_in_flow
            class_token = context.params[:class_token] || context.params[:join_token]
            # rubocop:disable Rails/DynamicFindBy
            school_class = SchoolClass.find_by_join_token(class_token)
            # rubocop:enable Rails/DynamicFindBy
            return unless school_class

            flow.data['school_class'] = {
              'join_token' => class_token,
              'school_class_id' => school_class.id,
              'school_id' => school_class.school_id
            }
            flow.data['school'] = {
              'school_id' => school_class.school_id
            }
          end

          def send_sms_code
            Register::SendSmsCodeApi.call(
              phone: form.output[:phone],
              flow: flow
            )
          end
        end
      end
    end
  end
end
