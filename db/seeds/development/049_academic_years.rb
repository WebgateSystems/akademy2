# frozen_string_literal: true

log('Create Academic Years...')

# Create academic years for each school
# This seed runs before 050_school_classes.rb to ensure academic years exist
School.find_each do |school|
  # Create current academic year (2025/2026) if it doesn't exist
  unless AcademicYear.exists?(school: school, year: '2025/2026')
    AcademicYear.create!(
      school: school,
      year: '2025/2026',
      is_current: true,
      started_at: Date.new(2025, 9, 1)
    )
  end
end
