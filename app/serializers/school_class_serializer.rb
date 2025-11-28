# frozen_string_literal: true

class SchoolClassSerializer < ApplicationSerializer
  attributes :id, :name, :year, :school_id, :created_at, :updated_at

  attribute :school_name do |school_class|
    school_class.school&.name
  end

  attribute :main_teacher do |school_class|
    assignment = TeacherClassAssignment.includes(:teacher)
                                       .where(school_class: school_class, role: 'main')
                                       .first
    if assignment&.teacher
      {
        id: assignment.teacher.id,
        name: [assignment.teacher.first_name, assignment.teacher.last_name].compact.join(' ')
      }
    end
  end

  attribute :teaching_staff do |school_class|
    assignments = TeacherClassAssignment.includes(:teacher)
                                        .where(school_class: school_class, role: 'teaching_staff')
    assignments.map do |assignment|
      {
        id: assignment.teacher.id,
        name: [assignment.teacher.first_name, assignment.teacher.last_name].compact.join(' ')
      }
    end
  end

  attribute :students_count do |school_class|
    StudentClassEnrollment.joins(:school_class)
                          .where(school_classes: { id: school_class.id, year: school_class.year })
                          .count
  end
end
