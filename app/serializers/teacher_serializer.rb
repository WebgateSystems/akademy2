# frozen_string_literal: true

class TeacherSerializer < ApplicationSerializer
  attributes :id, :first_name, :last_name, :email, :school_id, :created_at, :updated_at

  attribute :name do |teacher|
    [teacher.first_name, teacher.last_name].compact.join(' ').presence || teacher.email
  end

  attribute :school_name do |teacher|
    teacher.school&.name
  end

  attribute :phone, &:display_phone

  attribute :birth_date do |teacher|
    teacher.metadata&.dig('birth_date')
  end

  attribute :subjects do |_teacher|
    # TODO: Implement subjects association when available
    []
  end

  attribute :locked_at, &:locked_at

  attribute :is_locked do |teacher|
    teacher.locked_at.present?
  end

  attribute :confirmed_at, &:confirmed_at

  attribute :is_confirmed do |teacher|
    teacher.confirmed_at.present?
  end

  attribute :enrollment_status do |teacher, params|
    # Check enrollment status for the school from params
    if params && params[:school_id]
      enrollment = TeacherSchoolEnrollment.find_by(teacher: teacher, school_id: params[:school_id])
      enrollment&.status || 'none'
    else
      'none'
    end
  end

  attribute :enrollment_id do |teacher, params|
    # Return enrollment ID for approve/decline actions
    if params && params[:school_id]
      enrollment = TeacherSchoolEnrollment.find_by(teacher: teacher, school_id: params[:school_id])
      enrollment&.id
    end
  end
end
