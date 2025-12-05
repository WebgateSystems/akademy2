# frozen_string_literal: true

class CustomDeviseMailer < Devise::Mailer
  layout false # MJML templates are self-contained

  default reply_to: Settings.services.smtp.reply_to

  # Override reset_password_instructions to add role parameter for students
  def reset_password_instructions(record, token, opts = {})
    @role = record.student? ? 'student' : nil
    super
  end
end
