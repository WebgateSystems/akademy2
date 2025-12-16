# frozen_string_literal: true

namespace :wlatcy_moch do
  desc 'Delete the permanent test school "Włatcy Móch" and all associated data'
  task destroy: :environment do
    school_id = '77777777-3d96-492d-900e-777777777777'
    school = School.find_by(id: school_id)

    if school.nil?
      puts "⚠️  School 'Włatcy Móch' (ID: #{school_id}) not found. Nothing to delete."
      exit 0
    end

    puts "🗑️  Deleting school 'Włatcy Móch' and all associated data..."
    puts "   School: #{school.name} (#{school.slug})"

    # Count records before deletion
    user_ids = User.where(school: school).pluck(:id)
    class_ids = SchoolClass.where(school: school).pluck(:id)

    counts = {
      users: user_ids.count,
      user_roles: UserRole.where(user_id: user_ids).count,
      school_classes: class_ids.count,
      student_enrollments: StudentClassEnrollment.where(school_class_id: class_ids).count,
      teacher_enrollments: TeacherSchoolEnrollment.where(school: school).count,
      teacher_assignments: TeacherClassAssignment.where(school_class_id: class_ids).count,
      academic_years: AcademicYear.where(school: school).count,
      notifications: Notification.where(school: school).count,
      quiz_results: QuizResult.where(user_id: user_ids).count,
      certificates: Certificate.joins(:quiz_result).where(quiz_results: { user_id: user_ids }).count,
      events: Event.where(user_id: user_ids).count
    }

    puts "\n   Records to be deleted:"
    counts.each do |key, count|
      puts "   - #{key.to_s.humanize}: #{count}" if count.positive?
    end

    # Perform deletion in correct order (respecting foreign keys)
    ActiveRecord::Base.transaction do
      # Delete certificates first (depends on quiz_results)
      Certificate.joins(:quiz_result).where(quiz_results: { user_id: user_ids }).destroy_all

      # Delete quiz results
      QuizResult.where(user_id: user_ids).destroy_all

      # Delete events
      Event.where(user_id: user_ids).delete_all

      # Delete notifications
      Notification.where(school: school).delete_all
      Notification.where(user_id: user_ids).delete_all

      # Delete student enrollments
      StudentClassEnrollment.where(school_class_id: class_ids).delete_all

      # Delete teacher class assignments
      TeacherClassAssignment.where(school_class_id: class_ids).delete_all

      # Delete teacher school enrollments
      TeacherSchoolEnrollment.where(school: school).delete_all

      # Delete school classes
      SchoolClass.where(school: school).delete_all

      # Delete academic years
      AcademicYear.where(school: school).delete_all

      # Delete user roles
      UserRole.where(user_id: user_ids).delete_all

      # Delete users
      User.where(school: school).delete_all

      # Finally, delete the school itself
      school.destroy!
    end

    puts "\n✅ Successfully deleted school 'Włatcy Móch' and all associated data!"
    puts "   Total records removed: #{counts.values.sum + 1}"
  end

  desc 'Show info about the permanent test school "Włatcy Móch"'
  task info: :environment do
    school_id = '77777777-3d96-492d-900e-777777777777'
    school = School.find_by(id: school_id)

    if school.nil?
      puts "⚠️  School 'Włatcy Móch' (ID: #{school_id}) not found."
      puts "   Run 'rake db:seed' to create it."
      exit 0
    end

    puts "📚 School: #{school.name}"
    puts "   ID: #{school.id}"
    puts "   Slug: #{school.slug}"
    puts "   Address: #{school.address}, #{school.postcode} #{school.city}"
    puts ''

    # Classes
    classes = SchoolClass.where(school: school).order(:name)
    puts "📖 Classes (#{classes.count}):"
    classes.each do |klass|
      student_count = StudentClassEnrollment.where(school_class: klass).count
      puts "   - #{klass.name} (#{klass.year}): #{student_count} students"
    end
    puts ''

    # Adults (principal, school_manager, teacher) - login by email
    adult_role_keys = %w[principal school_manager teacher]
    adult_users = User.where(school: school)
                      .joins(:roles)
                      .where(roles: { key: adult_role_keys })
                      .distinct
                      .order(:last_name, :first_name)

    puts '👨‍🏫 Adults (login by EMAIL, password: devpass!):'
    adult_users.each do |user|
      roles = user.roles.where(key: adult_role_keys).pluck(:key).join(', ')
      puts "   - #{user.full_name}"
      puts "     Email: #{user.email}"
      puts "     Roles: #{roles}"
    end
    puts ''

    # Students - login by phone + PIN
    student_users = User.where(school: school)
                        .joins(:roles)
                        .where(roles: { key: 'student' })
                        .order(:last_name, :first_name)

    puts '🧒 Students (login by PHONE + PIN: 0000):'
    student_users.each do |user|
      enrollment = StudentClassEnrollment.joins(:school_class)
                                         .where(student_id: user.id, school_classes: { school_id: school.id })
                                         .first
      class_name = enrollment&.school_class&.name || 'N/A'
      puts "   - #{user.full_name} (class #{class_name})"
      puts "     Phone: #{user.phone}"
    end
    puts ''

    puts '🔑 Login summary:'
    puts '   Adults: email + password "devpass!"'
    puts '   Students: phone + PIN "0000"'
  end
end
