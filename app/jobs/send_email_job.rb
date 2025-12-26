# frozen_string_literal: true

require 'base64'

class SendEmailJob < BaseSidekiqJob
  sidekiq_options queue: :mail

  class << self
    # Enqueue with Sidekiq-strict JSON args (no Symbols, only native JSON types).
    # Supports passing ActiveRecord models (serialized to GlobalID `gid://...` string).
    def enqueue(mailer_class, mailer_action, *args)
      perform_async(
        normalize_for_sidekiq(mailer_class),
        normalize_for_sidekiq(mailer_action),
        *args.map { |a| normalize_for_sidekiq(a) }
      )
    end

    private

    def normalize_for_sidekiq(value)
      case value
      when Symbol then value.to_s
      when Array then normalize_array(value)
      when Hash  then normalize_hash(value)
      else normalize_object(value)
      end
    end

    def normalize_array(array)
      array.map { |v| normalize_for_sidekiq(v) }
    end

    def normalize_hash(hash)
      hash.each_with_object({}) do |(k, v), h|
        h[normalize_for_sidekiq(k).to_s] = normalize_for_sidekiq(v)
      end
    end

    def normalize_object(value)
      return value.to_global_id.to_s if value.respond_to?(:to_global_id) # "gid://app/Model/id"

      value
    end
  end

  # Wysyła email przez podany mailer
  #
  # @param mailer_class [String] nazwa klasy mailera, np. "CustomDeviseMailer"
  # @param mailer_action [String] nazwa metody mailera, np. "reset_password_instructions"
  # @param args [Array] argumenty przekazywane do metody mailera
  #
  # @example Wywołanie z Devise
  #   SendEmailJob.enqueue("CustomDeviseMailer", "reset_password_instructions", user, token, {})
  #
  # @example Przyszłe użycie - certyfikat
  #   SendEmailJob.enqueue("CertificateMailer", "send_certificate", user_id, certificate_url)
  #
  def perform(mailer_class, mailer_action, *args)
    mailer = mailer_class.constantize
    mailer.public_send(mailer_action, *deserialize_args(args)).deliver_now
  end

  private

  # Sidekiq stores args as JSON. When we need to pass ActiveRecord models, we pass GlobalID strings
  # (e.g. `user.to_global_id.to_s`) and locate them here.
  def deserialize_args(args)
    args.map { |arg| deserialize_arg(arg) }
  end

  def deserialize_arg(arg)
    return deserialize_string(arg) if arg.is_a?(String)
    return arg.map { |v| deserialize_arg(v) } if arg.is_a?(Array)
    return deserialize_hash(arg) if arg.is_a?(Hash)

    arg
  end

  def deserialize_string(value)
    return GlobalID::Locator.locate(value) if value.start_with?('gid://')

    decoded_gid = try_decode_gid_param(value)
    return GlobalID::Locator.locate(decoded_gid) if decoded_gid

    value
  end

  # Mailers (Devise included) commonly expect symbol keys in opts hash.
  def deserialize_hash(hash)
    hash.each_with_object({}) do |(k, v), h|
      key = k.is_a?(String) ? k.to_sym : k
      h[key] = deserialize_arg(v)
    end
  end

  def try_decode_gid_param(value)
    return nil unless value.is_a?(String)

    decoded = begin
      # `to_gid_param` uses URL-safe base64; padding may be omitted
      padded = value.ljust((value.length + 3) / 4 * 4, '=')
      Base64.urlsafe_decode64(padded)
    rescue ArgumentError
      nil
    end

    return nil unless decoded&.start_with?('gid://')

    decoded
  end
end
