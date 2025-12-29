# frozen_string_literal: true

class WebinarRegistration < ApplicationRecord
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :webinar_id, presence: true
  validates :email, uniqueness: { scope: :webinar_id, message: 'już zapisano na ten webinar' }

  def full_name
    "#{first_name} #{last_name}"
  end

  def send_confirmation_email!
    return if confirmation_sent_at.present?

    SendEmailJob.enqueue('WebinarMailer', 'registration_confirmation', self)
    update!(confirmation_sent_at: Time.current)
  end
end
