# frozen_string_literal: true

# Legacy model for backward compatibility with old notification system
# New notifications should use Notification model directly
class NotificationRead < ApplicationRecord
  belongs_to :user

  validates :notification_id, presence: true
  validates :user_id, uniqueness: { scope: :notification_id, message: 'Notification already marked as read' }

  before_validation :set_read_at, if: -> { read_at.nil? }

  scope :for_user, ->(user) { where(user: user) }
  scope :for_notification, ->(notification_id) { where(notification_id: notification_id) }

  private

  def set_read_at
    self.read_at = Time.current
  end
end
