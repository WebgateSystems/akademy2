# frozen_string_literal: true

class AcademicYearSerializer < ApplicationSerializer
  attributes :id, :year, :school_id, :is_current, :started_at, :ended_at, :created_at, :updated_at

  attribute :school_name do |academic_year|
    academic_year.school&.name
  end

  attribute :classes_count do |academic_year|
    SchoolClass.where(school: academic_year.school, year: academic_year.year).count
  end
end
