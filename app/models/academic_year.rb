# frozen_string_literal: true

class AcademicYear < ApplicationRecord
  belongs_to :school
  # NOTE: school_classes are linked by year (string), not by foreign key
  # Use SchoolClass.where(school: school, year: year) to find related classes

  validates :year, presence: true, uniqueness: { scope: :school_id }
  validates :school_id, presence: true
  validate :year_format_must_be_consecutive

  scope :current, -> { where(is_current: true) }
  scope :for_school, ->(school) { where(school: school) }
  scope :ordered, lambda {
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      order(Arel.sql("CAST(SPLIT_PART(year, '/', 1) AS INTEGER) ASC"))
    else
      # SQLite fallback
      order(Arel.sql('CAST(SUBSTR(year, 1, 4) AS INTEGER) ASC'))
    end
  }

  before_save :ensure_single_current_year

  private

  def ensure_single_current_year
    return unless is_current?

    # Unset other current years for the same school
    # rubocop:disable Rails/SkipsModelValidations
    # We need update_all here for performance and to avoid callbacks
    AcademicYear.where(school: school, is_current: true)
                .where.not(id: id)
                .update_all(is_current: false)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def year_format_must_be_consecutive
    return if year.blank?

    parts = year.split('/')
    return errors.add(:year, 'ma nieprawidłowy format (oczekiwany format: YYYY/YYYY)') unless parts.length == 2

    begin
      start_year = parts[0].to_i
      end_year = parts[1].to_i

      return errors.add(:year, 'nie może być pusty') if start_year.zero? || end_year.zero?

      errors.add(:year, 'musi składać się z dwóch kolejnych lat (np. 2025/2026)') unless end_year == start_year + 1
    rescue StandardError
      errors.add(:year, 'ma nieprawidłowy format (oczekiwany format: YYYY/YYYY)')
    end
  end
end
