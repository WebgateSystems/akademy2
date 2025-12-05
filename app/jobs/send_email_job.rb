# frozen_string_literal: true

class SendEmailJob < ApplicationJob
  queue_as :default

  # Wysyła email przez podany mailer
  #
  # @param mailer_class [String] nazwa klasy mailera, np. "CustomDeviseMailer"
  # @param mailer_action [String] nazwa metody mailera, np. "reset_password_instructions"
  # @param args [Array] argumenty przekazywane do metody mailera
  #
  # @example Wywołanie z Devise
  #   SendEmailJob.perform_later("CustomDeviseMailer", "reset_password_instructions", user, token, {})
  #
  # @example Przyszłe użycie - certyfikat
  #   SendEmailJob.perform_later("CertificateMailer", "send_certificate", user_id, certificate_url)
  #
  def perform(mailer_class, mailer_action, *args)
    mailer = mailer_class.constantize
    mailer.public_send(mailer_action, *args).deliver_now
  end
end
