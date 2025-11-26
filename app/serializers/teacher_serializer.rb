# frozen_string_literal: true

class TeacherSerializer < ApplicationSerializer
  attributes :id, :first_name, :last_name, :email, :school_id, :created_at, :updated_at

  attribute :name do |teacher|
    [teacher.first_name, teacher.last_name].compact.join(' ').presence || teacher.email
  end

  attribute :school_name do |teacher|
    teacher.school&.name
  end

  attribute :phone do |teacher|
    teacher.metadata&.dig('phone')
  end

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
end
