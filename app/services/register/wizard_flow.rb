# frozen_string_literal: true

module Register
  class WizardFlow
    SESSION_KEY = 'register_wizard'

    STEP_RULES = {
      profile: ->(_flow) { true },
      verify_phone: ->(flow) { flow.profile_completed? },
      set_pin: ->(flow) { flow.phone_verified? },
      set_pin_confirm: ->(flow) { flow.phone_verified? && flow.pin_created? },
      confirm_email: ->(flow) { flow.user_created? }
    }.freeze

    def initialize(session)
      @session = session
      @session[SESSION_KEY] ||= {}
    end

    def data
      @session[SESSION_KEY]
    end

    def [](key)
      data[key.to_s]
    end

    def update(step, attrs)
      step_key = step.to_s
      data[step_key] ||= {}
      data[step_key].merge!(attrs)
    end

    def finish!
      @session.delete(SESSION_KEY)
    end

    # --- Progress tracking ----

    def profile_completed?
      data['profile'].present?
    end

    def phone_verified?
      data.dig('phone', 'verified') == true
    end

    def pin_created?
      data.dig('pin_temp', 'pin').present?
    end

    def pin_confirmed?
      data.dig('pin', 'pin').present?
    end

    def user_created?
      data.dig('user', 'user_id').present?
    end

    def can_access?(step)
      rule = STEP_RULES[step.to_sym]
      rule ? rule.call(self) : false
    end
  end
end
