module Register
  class SetPinConfirmSubmit < BaseInteractor
    def call
      valid_pin_and_match? ? process_success : fail_pin_mismatch
    end

    private

    def process_success
      save_pin_to_flow
      context.form = current_form

      save_user || fail_user_creation
    end

    def save_pin_to_flow
      context.flow.update(:pin, { 'pin' => current_form.pin })
    end

    def save_user
      user = build_user_from_flow

      unless user.save
        # rubocop:disable Rails/Output
        puts ''
        puts '=' * 60
        puts '❌ USER CREATION FAILED'
        puts '=' * 60
        puts "   Email: #{user.email}"
        puts "   Errors: #{user.errors.full_messages.join(', ')}"
        puts '=' * 60
        puts ''
        # rubocop:enable Rails/Output
        Rails.logger.error "[REGISTER] User creation failed: #{user.errors.full_messages.join(', ')}"
        return false
      end

      # Assign student role to the new user
      assign_student_role(user)

      context.flow.update(:user, { 'user_id' => user.id })
      user.send_confirmation_instructions
      true
    end

    def assign_student_role(user)
      student_role = Role.find_by(key: 'student')
      return unless student_role

      # Student registers without school - they join school later via QR/link invitation
      UserRole.create!(user: user, role: student_role, school: nil)

      # rubocop:disable Rails/Output
      puts ''
      puts '=' * 60
      puts '✅ STUDENT ROLE ASSIGNED'
      puts '=' * 60
      puts "   User: #{user.email}"
      puts "   Phone: #{user.phone}"
      puts '   School: (none - will join via invitation)'
      puts '=' * 60
      puts ''
      # rubocop:enable Rails/Output
    end

    def fail_user_creation
      user = build_user_from_flow
      user.valid? # trigger validation to populate errors
      context.redirect_path = redirect_to_profile
      context.fail!(message: user.errors.full_messages.to_sentence)
    end

    def fail_pin_mismatch
      context.form = current_form
      context.fail!(message: 'Codes do not match')
    end

    def redirect_to_profile
      Rails.application.routes.url_helpers.register_profile_path
    end

    def valid_pin_and_match?
      current_form.valid? && current_form.pin == stored_pin
    end

    def current_form
      @current_form ||= PinForm.new(pin: submitted_pin)
    end

    def submitted_pin
      context.params[:pin_hidden]
    end

    def stored_pin
      context.flow['pin_temp']['pin']
    end

    def build_user_from_flow
      Register::BuildUserFromFlow.call(flow: context.flow).user
    end
  end
end
