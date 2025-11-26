class Event < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :school, optional: true

  scope :recent, -> { order(occurred_at: :desc, created_at: :desc) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_school, ->(school) { where(school: school) }
end
