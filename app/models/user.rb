class User < ApplicationRecord
  # JWT revocation via JTIMatcher (wymaga kolumny :jti)
  include Devise::JWT::RevocationStrategies::JTIMatcher

  belongs_to :school, optional: true
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :student_class_enrollments, foreign_key: 'student_id', dependent: :destroy, inverse_of: :student
  has_many :school_classes, through: :student_class_enrollments
  has_many :parent_student_links, foreign_key: 'parent_id', dependent: :destroy, inverse_of: :parent
  has_many :students, through: :parent_student_links, source: :student
  has_many :child_links, foreign_key: 'student_id', class_name: 'ParentStudentLink',
                         dependent: :destroy, inverse_of: :student
  has_many :parents, through: :child_links, source: :parent
  has_many :teacher_class_assignments, foreign_key: 'teacher_id', dependent: :destroy, inverse_of: :teacher
  has_many :assigned_classes, through: :teacher_class_assignments, source: :school_class
  has_many :teacher_school_enrollments, foreign_key: 'teacher_id', dependent: :destroy, inverse_of: :teacher
  has_many :student_videos, dependent: :destroy
  has_many :student_video_likes, dependent: :destroy

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :confirmable,
         :lockable,
         :timeoutable,
         :trackable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self

  after_save :sync_notifications_for_teacher, if: :saved_change_to_confirmed_at?
  after_save :sync_notifications_for_student, if: :saved_change_to_confirmed_at?

  def admin?
    roles.pluck(:key).include?('admin')
  end

  def teacher?
    roles.pluck(:key).include?('teacher')
  end

  def student?
    roles.pluck(:key).include?('student')
  end

  def parent?
    roles.pluck(:key).include?('parent')
  end

  # Get phone with fallback: first check phone column, then metadata['phone']
  def display_phone
    phone.presence || metadata&.dig('phone')
  end

  # Check if user account is active (not locked)
  def active?
    locked_at.blank?
  end

  # Full name combining first and last name
  def full_name
    [first_name, last_name].compact.join(' ').presence || email
  end

  def inactive?
    locked_at.present?
  end

  # Theme accessor stored in metadata
  def theme
    metadata&.dig('theme') || 'light'
  end

  def theme=(value)
    self.metadata ||= {}
    self.metadata['theme'] = value
  end

  # Override Devise method to prevent locked users from authenticating
  def active_for_authentication?
    super && active?
  end

  # Custom message for locked accounts
  def inactive_message
    locked_at.present? ? :locked : super
  end

  # Override Devise method to send emails via SendEmailJob
  def send_devise_notification(notification, *args)
    SendEmailJob.perform_later('CustomDeviseMailer', notification.to_s, self, *args)
  end

  private

  def sync_notifications_for_teacher
    return unless teacher?
    return unless school

    if confirmed_at.nil?
      # Teacher is now unconfirmed - create notification
      NotificationService.create_teacher_awaiting_approval(teacher: self, school: school)
    elsif confirmed_at.present? && saved_change_to_confirmed_at?
      # Teacher was just confirmed - resolve notification
      NotificationService.resolve_teacher_notification(teacher: self, school: school)
    end
  end

  def sync_notifications_for_student
    return unless student?
    return unless school

    if confirmed_at.nil?
      # Student is now unconfirmed - create notification
      NotificationService.create_student_awaiting_approval(student: self, school: school)
    elsif confirmed_at.present? && saved_change_to_confirmed_at?
      # Student was just confirmed - resolve notification (if we implement this)
      # NotificationService.resolve_student_notification(student: self, school: school)
    end
  end
end
