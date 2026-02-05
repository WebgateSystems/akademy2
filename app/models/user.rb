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
  has_many :quiz_results, dependent: :destroy

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

  def admin? = roles.pluck(:key).include?('admin')
  def manager? = roles.pluck(:key).include?('manager')
  def admin_panel_access? = admin? || manager?
  def teacher? = roles.pluck(:key).include?('teacher')
  def student? = roles.pluck(:key).include?('student')
  def parent? = roles.pluck(:key).include?('parent')
  def display_phone = phone.presence || metadata&.dig('phone')
  def active? = locked_at.blank?
  def inactive? = locked_at.present?
  def full_name = [first_name, last_name].compact.join(' ').presence || email

  # Metadata accessors for theme and locale
  def theme = metadata&.dig('theme') || 'light'
  def locale = metadata&.dig('locale') || 'pl'

  def theme=(value)
    (self.metadata ||= {})['theme'] = value
  end

  def locale=(value)
    (self.metadata ||= {})['locale'] = value
  end

  def blocked_by_admin? = RequestBlockRule.blocked?(user_id: id)
  def active_for_authentication? = super && active? && !blocked_by_admin?

  def inactive_message
    return :blocked if blocked_by_admin?
    return :locked if locked_at.present?

    super
  end

  def send_devise_notification(notification, *args)
    SendEmailJob.enqueue('CustomDeviseMailer', notification.to_s, self, *args)
  end

  private

  def sync_notifications_for_teacher
    return unless teacher? && school

    if confirmed_at.nil?
      NotificationService.create_teacher_awaiting_approval(teacher: self, school: school)
    elsif saved_change_to_confirmed_at?
      NotificationService.resolve_teacher_notification(teacher: self, school: school)
    end
  end

  def sync_notifications_for_student
    return unless student? && school

    NotificationService.create_student_awaiting_approval(student: self, school: school) if confirmed_at.nil?
  end
end
