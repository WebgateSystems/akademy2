# frozen_string_literal: true

# This seed runs after 050_school_classes.rb to ensure all academic years
# referenced by classes exist in the AcademicYear table
log('Sync Academic Years with School Classes...')

School.find_each do |school|
  # Get all unique years from school classes
  years_from_classes = SchoolClass.where(school: school).distinct.pluck(:year)

  years_from_classes.each do |year|
    # Create academic year if it doesn't exist
    next if AcademicYear.exists?(school: school, year: year)

    AcademicYear.create!(
      school: school,
      year: year,
      is_current: (year == '2025/2026'), # Only 2025/2026 is current by default
      started_at: year.start_with?('2025') ? Date.new(2025, 9, 1) : Date.new(2024, 9, 1),
      ended_at: year.start_with?('2025') ? nil : Date.new(2025, 6, 30)
    )
  end
end
