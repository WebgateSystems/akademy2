class TwilioService
  include Singleton

  # rubocop:disable Metrics/ParameterLists
  def send_sms(to:, body:, from: nil, account_sid: nil, auth_token: nil, messaging_service_sid: nil)
    unless allowed_environment?
      log "[Twilio] SMS skipped (env=#{Rails.env}) to #{to}: #{body}"
      return { success: true, skipped: true }
    end

    log "[Twilio] Sending SMS to #{to}: #{body}"

    params = build_params(to: to, body: body, from: from, messaging_service_sid: messaging_service_sid)
    client = build_client(account_sid, auth_token)

    create_message(client, params)
  end
  # rubocop:enable Metrics/ParameterLists

  private

  def allowed_environment?
    Rails.env.in?(%w[production staging])
  end

  # --------------------------
  # PARAMS BUILDING
  # --------------------------
  def build_params(to:, body:, from:, messaging_service_sid:)
    normalized_to = normalize_phone(to)

    params = { to: normalized_to, body: body }

    if messaging_service_sid.present?
      params[:messaging_service_sid] = messaging_service_sid
    else
      params[:from] = normalize_phone(from.presence || default_from_number)
    end

    params
  end

  # --------------------------
  # MESSAGE CREATION
  # --------------------------
  def create_message(client, params)
    message = client.messages.create(**params)

    log "[Twilio] Sent successfully SID=#{message.sid}"

    {
      success: true,
      sid: message.sid,
      status: message.status
    }
  rescue Twilio::REST::RestError => e
    log "[Twilio] Error: #{e.message} (#{e.code})", :error

    {
      success: false,
      error: e.message,
      code: e.code
    }
  end

  # --------------------------
  # HELPERS
  # --------------------------
  def default_from_number
    Settings.services.twilio.phone_number
  end

  def normalize_phone(phone)
    phone = phone.to_s.strip
    return phone if phone.start_with?('+')

    "+#{phone.gsub(/\D/, '')}"
  end

  def build_client(account_sid, auth_token)
    sid   = account_sid.presence || Settings.services.twilio.account_sid
    token = auth_token.presence  || Settings.services.twilio.auth_token

    Twilio::REST::Client.new(sid, token)
  end

  def log(message, level = :info)
    Rails.logger.public_send(level, message)
  end

  class << self
    delegate :send_sms, to: :instance
  end
end
