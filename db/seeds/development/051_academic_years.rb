# frozen_string_literal: true

# This seed should run before 050_school_classes.rb
# Create academic years for each school
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

  # Create previous academic year (2024/2025) if classes exist for it
  if SchoolClass.where(school: school, year: '2024/2025').exists? && !AcademicYear.exists?(school: school, year: '2024/2025')
    AcademicYear.create!(
      school: school,
      year: '2024/2025',
      is_current: false,
      started_at: Date.new(2024, 9, 1),
      ended_at: Date.new(2025, 6, 30)
    )
  end
end
