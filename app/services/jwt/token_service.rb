module Jwt
  class TokenService
    SECRET_KEY = Rails.application.config.secret_key_base

    def self.encode(payload, exp = JWT_TOKEN_TIME_EXP.hours.from_now)
      payload[:exp] = exp.to_i
      JWT.encode(payload, SECRET_KEY)
    end

    def self.decode(token)
      decoded = JWT.decode(token, SECRET_KEY)[0]
      HashWithIndifferentAccess.new decoded
    rescue JWT::ExpiredSignature
      nil
    end
  end
end
