class StudentClassEnrollment < ApplicationRecord
  belongs_to :school_class
  belongs_to :student, class_name: 'User', foreign_key: 'student_id'
end
