class RegistrationFlow < ApplicationRecord
  encrypts :data

  attribute :step, :string, default: 'profile'
  attribute :expires_at, :datetime, default: -> { 30.minutes.from_now }
  attribute :data, :jsonb, default: {}

  validates :step, presence: true
  validates :expires_at, presence: true

  scope :active,  -> { where('expires_at > ?', Time.current) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }

  def expired?
    expires_at < Time.current
  end
end
