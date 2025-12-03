module Register
  class TeacherProfileSubmit < BaseInteractor
    def call
      current_form.valid? ? good_outcome : bad_outcome
    end

    private

    def good_outcome
      context.form = current_form
      context.flow.update(:profile, context.form.to_h)
      send_sms_code
    end

    def bad_outcome
      context.form = current_form
      context.fail!(message: 'Validation failed')
    end

    def current_form
      @current_form ||= ::Register::TeacherProfileForm.new(permit_params)
    end

    def permit_params
      # Rails generates parameter name based on model class name
      # TeacherProfileForm -> register_teacher_profile_form
      param_key = if context.params.key?(:register_teacher_profile_form)
                    :register_teacher_profile_form
                  else
                    :register_profile_form
                  end

      # Extract join_token from params and store in flow (it's not part of the form model)
      form_params = context.params.require(param_key)
      join_token = form_params[:join_token]
      if join_token.present?
        school_data = context.flow['school'] || {}
        school_data['join_token'] = join_token
        context.flow.update(:school, school_data)
      end

      # Only permit form fields, not join_token (it's stored in flow)
      form_params.permit(
        :first_name,
        :last_name,
        :email,
        :phone,
        :password,
        :password_confirmation
      )
    end

    def send_sms_code
      Register::SendSmsCode.call(phone: context.form.phone, flow: context.flow)
    end
  end
end
