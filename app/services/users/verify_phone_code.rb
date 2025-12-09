# frozen_string_literal: true

module Users
  class VerifyPhoneCode
    RESULT = %i[ok invalid expired no_request].freeze

    def initialize(user, submitted_code)
      @user = user
      @code = submitted_code
      @metadata = user.metadata || {}
      @data = @metadata['phone_verification'] || {}
    end

    def call
      return :no_request unless data['code']
      return :expired if expired?

      if code != data['code']
        increment_attempts!
        return :invalid
      end

      mark_verified!
      :ok
    end

    private

    attr_reader :user, :metadata, :data, :code

    def sent_at
      @sent_at ||= begin
        Time.iso8601(data['sent_at'])
      rescue StandardError
        nil
      end
    end

    def expired?
      sent_at.nil? || Time.current - sent_at > 5.minutes
    end

    def increment_attempts!
      data['attempts'] = data.fetch('attempts', 0) + 1
      metadata['phone_verification'] = data
      user.update!(metadata: metadata)
    end

    def mark_verified!
      metadata['phone_verified'] = true
      metadata['phone_verification'] = nil
      user.update!(metadata: metadata)
    end
  end
end
