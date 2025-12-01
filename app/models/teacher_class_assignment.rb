class TeacherClassAssignment < ApplicationRecord
  belongs_to :school_class
  belongs_to :teacher, class_name: 'User', inverse_of: :teacher_class_assignments
end
