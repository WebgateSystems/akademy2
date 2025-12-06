class TwilioService
  include Singleton

  # Thread-safe client initializationg
  def initialize
    @client_mutex = Mutex.new
    @clients = {}
  end

  # Send SMS message - simple and clean interface
  def send_sms(from:, to:, body:, account_sid: nil, auth_token: nil, messaging_service_sid: nil)
    Rails.logger.info "=== TWILIO SERVICE SEND_SMS CALLED ==="
    Rails.logger.info "From: #{from}, To: #{to}, Body: #{body}"
    Rails.logger.info "Account SID: #{account_sid}, Messaging Service SID: #{messaging_service_sid}"

    client = get_client(account_sid: account_sid, auth_token: auth_token)

    normalized_to = normalize_msisdn(to)
    normalized_from = normalize_msisdn(from) if messaging_service_sid.blank?

    message_params = {
      to: normalized_to,
      body: body
    }

    # Use MessagingServiceSid if provided, otherwise use from number
    if messaging_service_sid.present?
      message_params[:messaging_service_sid] = messaging_service_sid
    else
      message_params[:from] = normalized_from
    end

    Rails.logger.debug "SMS params: #{message_params.inspect}"

    begin
      response = client.messages.create(**message_params)
      Rails.logger.info "SMS sent successfully: #{response.sid}"

      {
        success: true,
        message_sid: response.sid,
        status: response.status,
        to: response.to,
        from: response.from,
        body: response.body
      }
    rescue Twilio::REST::RestError => e
      Rails.logger.error "Twilio SMS error: #{e.message} (Code: #{e.code})"
      {
        success: false,
        error: e.message,
        error_code: e.code
      }
    rescue => e
      Rails.logger.error "Unexpected SMS error: #{e.message}"
      {
        success: false,
        error: e.message,
        error_code: (e.respond_to?(:code) ? e.code : nil)
      }
    end
  end

  def webhook_verify?(signature, url, params)
    begin
      # Twilio validator expects a Hash of params (for form-encoded requests)
      params_hash =
        if defined?(ActionController::Parameters) && params.is_a?(ActionController::Parameters)
          params.to_unsafe_h
        elsif params.respond_to?(:to_h)
          params.to_h
        else
          params || {}
        end

      # Ensure string keys and drop Rails-internal routing keys
      params_hash = params_hash.transform_keys(&:to_s)
      params_hash = params_hash.except("controller", "action")

      Twilio::Security::RequestValidator
        .new(Settings.twilio.auth_token)
        .validate(url, params_hash, signature)
    rescue => e
      Rails.logger.error "Webhook verification failed: #{e.message}"
      false
    end
  end

  private

  # Normalize to E.164 string, ensuring it starts with '+'; accept integers or strings
  def normalize_msisdn(value)
    str = value.to_s.strip
    return str if str.start_with?("+") || str.start_with?("whatsapp:")
    digits = str.gsub(/\D/, "")
    return "" if digits.empty?
    "+#{digits}"
  end

  # Get thread-safe Twilio client
  def get_client(account_sid: nil, auth_token: nil)
    @client_mutex.synchronize do
      # Use provided credentials or fallback to global settings
      sid = account_sid.presence || Settings.twilio.account_sid
      token = auth_token.presence || Settings.twilio.auth_token

      Rails.logger.debug "Twilio credentials: sid=#{sid}, token=#{token ? token[0..10] + '...' : 'nil'}"

      if sid.blank? || token.blank?
        raise ArgumentError, "Missing Twilio credentials: sid=#{sid.inspect}, token=#{token.inspect}"
      end

      client_key = "#{sid}_#{token[0..10]}" # Use partial token as key for security

      # In test, do not cache across examples to avoid double leakage
      if Rails.env.test?
        Rails.logger.debug "Creating fresh Twilio client (test env) for #{sid}"
        return Twilio::REST::Client.new(sid, token)
      end

      @clients[client_key] ||= begin
        Rails.logger.debug "Creating new Twilio client for #{sid}"
        Twilio::REST::Client.new(sid, token)
      end
    end
  end

  # Class methods for easy access
  class << self
    delegate :send_sms, :send_whatsapp, to: :instance
  end
end
