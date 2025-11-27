# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user, optional: true # User who triggered the notification
  belongs_to :school, optional: true # School context
  belongs_to :read_by_user, class_name: 'User', optional: true

  validates :notification_type, presence: true
  validates :title, presence: true
  validates :message, presence: true
  validates :target_role, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }
  scope :unresolved, -> { where(resolved_at: nil) }
  scope :for_role, ->(role) { where(target_role: role) }
  scope :for_school, ->(school) { where(school: school) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def resolved?
    resolved_at.present?
  end

  def mark_as_read!(user)
    return if read?

    update!(read_at: Time.current, read_by_user: user)
  end

  def mark_as_resolved!
    return if resolved?

    update!(resolved_at: Time.current)
  end
end
