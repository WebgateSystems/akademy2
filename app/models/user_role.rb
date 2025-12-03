class UserRole < ApplicationRecord
  belongs_to :user
  belongs_to :role
  belongs_to :school, optional: true

  validate :student_role_exclusivity

  private

  # Student role is exclusive - students cannot have any other roles,
  # and non-students cannot become students
  def student_role_exclusivity
    return unless user && role

    if adding_student_role?
      validate_no_existing_roles
    else
      validate_user_not_student
    end
  end

  def adding_student_role?
    role.key == 'student'
  end

  def validate_no_existing_roles
    existing_roles = user.roles.where.not(id: role.id)
    return if existing_roles.empty?

    errors.add(:role, 'student nie może posiadać innych ról')
  end

  def validate_user_not_student
    return unless user.roles.exists?(key: 'student')

    errors.add(:role, 'nie można dodać innych ról do studenta')
  end
end
