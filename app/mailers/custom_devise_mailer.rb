# frozen_string_literal: true

class CustomDeviseMailer < Devise::Mailer
  # Override reset_password_instructions to add role parameter for students
  def reset_password_instructions(record, token, opts = {})
    @role = record.student? ? 'student' : nil
    super
  end
end
