# frozen_string_literal: true

module Register
  class WizardFlow
    attr_accessor :phone

    SESSION_KEY = "register_wizard".freeze

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

    def phone
      data['phone']
    end


    def clear!
      @session.delete(SESSION_KEY)
    end

    def profile_completed?
      data["profile"].present?
    end

    def phone_verified?
      data.dig("phone", "verified") == true
    end

    def user_created?
      data["user_id"].present?
    end
  end
end
