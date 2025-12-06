# frozen_string_literal: true

module InviteTokens
  # Stub validator for invite tokens
  # TODO: Implement actual token validation logic
  class Validator
    def self.call!(_token)
      raise ActiveRecord::RecordNotFound, _('Token not found')
    end
  end
end
