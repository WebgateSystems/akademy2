class SchoolClass < ApplicationRecord
  belongs_to :school
  has_many :teacher_class_assignments, dependent: :destroy
  has_many :teachers, through: :teacher_class_assignments, source: :teacher
  has_many :student_class_enrollments, dependent: :destroy
  has_many :students, through: :student_class_enrollments, source: :student

  validates :name, presence: true
  validates :year, presence: true
end
