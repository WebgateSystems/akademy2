class TeacherClassAssignment < ApplicationRecord
  belongs_to :school_class
  belongs_to :teacher, class_name: 'User', inverse_of: :teacher_class_assignments

  validates :teacher_id, uniqueness: { scope: :school_class_id, message: 'jest już przypisany do tej klasy' }
end
