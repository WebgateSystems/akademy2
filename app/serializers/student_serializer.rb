# frozen_string_literal: true

class StudentSerializer < ApplicationSerializer
  CURRENT_ACADEMIC_YEAR = '2025/2026'

  attributes :id, :first_name, :last_name, :email, :school_id, :created_at, :updated_at, :locked_at, :confirmed_at

  attribute :name do |student|
    [student.first_name, student.last_name].compact.join(' ').presence || student.email
  end

  attribute :school_name do |student|
    student.school&.name
  end

  attribute :phone do |student|
    student.metadata&.dig('phone')
  end

  attribute :birth_date do |student|
    student.metadata&.dig('birth_date')
  end

  attribute :is_locked do |student|
    student.locked_at.present?
  end

  attribute :is_confirmed do |student|
    student.confirmed_at.present?
  end

  attribute :class_name do |student|
    current_class = student.student_class_enrollments
                           .joins(:school_class)
                           .where(school_classes: { year: CURRENT_ACADEMIC_YEAR })
                           .first
    current_class&.school_class&.name
  end
end
