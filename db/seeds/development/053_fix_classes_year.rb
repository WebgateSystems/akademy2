# frozen_string_literal: true

# This seed fixes classes to match current academic year
# Run this if classes have wrong year or students are not showing up

log('Fix Classes Year to Match Current Academic Year...')

School.find_each do |school|
  current_year = school.current_academic_year_value
  Rails.logger.debug "\nSchool: #{school.name}"
  Rails.logger.debug "  Current academic year: #{current_year}"

  # Ensure academic year exists
  unless AcademicYear.exists?(school: school, year: current_year)
    AcademicYear.create!(
      school: school,
      year: current_year,
      is_current: true,
      started_at: current_year.start_with?('2025') ? Date.new(2025, 9, 1) : Date.new(2024, 9, 1)
    )
    Rails.logger.debug "  Created AcademicYear: #{current_year}"
  end

  # Check classes
  classes = SchoolClass.where(school: school)
  Rails.logger.debug "  Total classes: #{classes.count}"

  # Count classes by year
  classes_by_year = classes.group_by(&:year)
  classes_by_year.each do |year, year_classes|
    Rails.logger.debug "  Classes with year #{year}: #{year_classes.count}"
  end

  # Update classes to current year if they don't match
  classes_with_wrong_year = classes.where.not(year: current_year)
  if classes_with_wrong_year.any?
    Rails.logger.debug "  Updating #{classes_with_wrong_year.count} classes to year #{current_year}..."
    classes_with_wrong_year.update_all(year: current_year)
    Rails.logger.debug '  Updated!'
  else
    Rails.logger.debug "  All classes already have correct year (#{current_year})"
  end

  # Check students
  all_students = User.joins(:user_roles)
                     .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                     .where(user_roles: { school_id: school.id }, roles: { key: 'student' })
                     .distinct
  Rails.logger.debug "  Total students: #{all_students.count}"

  current_year_students = User.joins(:user_roles)
                              .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                              .joins('INNER JOIN student_class_enrollments ON student_class_enrollments.student_id = users.id')
                              .joins('INNER JOIN school_classes ON school_classes.id = student_class_enrollments.school_class_id')
                              .where(user_roles: { school_id: school.id }, roles: { key: 'student' })
                              .where(school_classes: { year: current_year, school_id: school.id })
                              .distinct
  Rails.logger.debug "  Students in current year classes: #{current_year_students.count}"
end

Rails.logger.debug "\n=== Summary ==="
Rails.logger.debug "Total schools: #{School.count}"
Rails.logger.debug "Total classes: #{SchoolClass.count}"
Rails.logger.debug "Total students: #{User.joins(:roles).where(roles: { key: 'student' }).count}"
Rails.logger.debug "Total enrollments: #{StudentClassEnrollment.count}"
