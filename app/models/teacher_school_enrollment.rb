class TeacherSchoolEnrollment < ApplicationRecord
  belongs_to :school
  belongs_to :teacher, class_name: 'User'

  validates :teacher_id, uniqueness: { scope: :school_id, message: 'already has an enrollment for this school' }
  validates :status, presence: true

  before_validation :set_default_status, on: :create

  private

  def set_default_status
    self.status ||= 'pending'
  end
end
