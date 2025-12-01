# frozen_string_literal: true

class ParentSerializer
  include JSONAPI::Serializer

  set_type :parent

  attributes :first_name, :last_name, :email, :phone, :birthdate, :is_locked

  attribute :school_name do |parent|
    parent.school&.name
  end

  attribute :phone do |parent|
    parent.metadata&.dig('phone') || parent.phone
  end

  attribute :is_locked do |parent|
    parent.locked_at.present?
  end

  attribute :students do |parent, params|
    school_id = params&.dig(:school_id)
    return [] unless school_id

    # Get students linked to this parent for the given school
    current_year = parent.school&.current_academic_year_value
    return [] unless current_year

    parent.parent_student_links
          .joins(:student)
          .joins('INNER JOIN user_roles ON user_roles.user_id = users.id')
          .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
          .where(user_roles: { school_id: school_id }, roles: { key: 'student' })
          .includes(:student)
          .map do |link|
      student = link.student
      current_class = student.student_class_enrollments
                             .joins(:school_class)
                             .where(school_classes: { year: current_year })
                             .first
      # Check birthdate field first, then fall back to metadata for backwards compatibility
      birthdate_value = if student.birthdate.present?
                          student.birthdate.strftime('%d.%m.%Y')
                        else
                          student.metadata&.dig('birth_date')
                        end
      {
        id: student.id,
        first_name: student.first_name,
        last_name: student.last_name,
        birthdate: birthdate_value,
        class_name: current_class&.school_class&.name || '—',
        relation: link.relation
      }
    end
  end
end
