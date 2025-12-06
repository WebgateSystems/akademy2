# frozen_string_literal: true

module InviteTokens
  # Simple invite data structure
  Invite = Struct.new(:token, :kind, :school_id, :school_class_id, :used, keyword_init: true) do
    def mark_used!
      self.used = true
    end

    def used?
      used == true
    end
  end

  # Validator for invite tokens
  # In production, this should validate against a database
  # In tests, you can register invites using InviteTokens::Validator.register
  class Validator
    class << self
      def call!(token)
        raise ActiveRecord::RecordNotFound, 'Token not found' if token.blank?

        invite = registry[token]
        raise ActiveRecord::RecordNotFound, 'Token not found' unless invite

        invite
      end

      # Register an invite for testing purposes
      def register(token:, kind:, school_id:, school_class_id: nil)
        invite = Invite.new(
          token: token,
          kind: kind,
          school_id: school_id,
          school_class_id: school_class_id,
          used: false
        )
        registry[token] = invite
        invite
      end

      # Clear all registered invites (useful for test cleanup)
      def clear_registry!
        registry.clear
      end

      def registry
        # Use Rails.application for persistence across Zeitwerk reloads
        Rails.application.config.invite_tokens_registry ||= {}
      end
    end
  end
end
