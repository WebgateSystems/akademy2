class ParentStudentLink < ApplicationRecord
  belongs_to :parent, class_name: 'User'
  belongs_to :student, class_name: 'User'

  validates :relation, presence: true
  validates :relation, inclusion: { in: %w[mother father guardian other] }
end
