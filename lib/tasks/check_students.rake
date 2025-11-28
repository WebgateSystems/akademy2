namespace :db do
  desc 'Check students and classes status'
  task check_students: :environment do
    puts '=== Checking Schools ==='
    School.find_each do |school|
      puts "\nSchool: #{school.name} (ID: #{school.id})"
      current_year = school.current_academic_year_value
      puts "  Current academic year: #{current_year}"

      academic_year = school.current_academic_year
      if academic_year
        puts "  AcademicYear record: #{academic_year.year} (is_current: #{academic_year.is_current})"
      else
        puts '  AcademicYear record: NONE FOUND!'
      end

      puts "\n=== Classes for #{school.name} ==="
      classes = SchoolClass.where(school: school)
      puts "  Total classes: #{classes.count}"

      classes_by_year = classes.group_by(&:year)
      classes_by_year.each do |year, year_classes|
        puts "  Year #{year}: #{year_classes.count} classes"
        year_classes.first(5).each do |sc|
          enrollment_count = StudentClassEnrollment.where(school_class: sc).count
          puts "    - #{sc.name}: #{enrollment_count} students enrolled"
        end
        puts "    ... (#{year_classes.count - 5} more)" if year_classes.count > 5
      end

      puts "\n=== Students for #{school.name} ==="
      all_students = User.joins(:user_roles)
                         .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                         .where(user_roles: { school_id: school.id }, roles: { key: 'student' })
                         .distinct
      puts "  Total students in school: #{all_students.count}"

      # Students enrolled in current year classes
      current_year_students = User.joins(:user_roles)
                                  .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                                  .joins('INNER JOIN student_class_enrollments ' \
                                         'ON student_class_enrollments.student_id = users.id')
                                  .joins('INNER JOIN school_classes ' \
                                         'ON school_classes.id = student_class_enrollments.school_class_id')
                                  .where(user_roles: { school_id: school.id }, roles: { key: 'student' })
                                  .where(school_classes: { year: current_year, school_id: school.id })
                                  .distinct
      puts "  Students in current year (#{current_year}) classes: #{current_year_students.count}"

      # Students enrolled in other year classes
      enrollment_join = 'INNER JOIN student_class_enrollments ' \
                         'ON student_class_enrollments.student_id = users.id'
      class_join = 'INNER JOIN school_classes ' \
                   'ON school_classes.id = student_class_enrollments.school_class_id'
      other_year_students = User.joins(:user_roles)
                                .joins('INNER JOIN roles ON user_roles.role_id = roles.id')
                                .joins(enrollment_join)
                                .joins(class_join)
                                .where(user_roles: { school_id: school.id }, roles: { key: 'student' })
                                .where.not(school_classes: { year: current_year })
                                .distinct
      puts "  Students in other year classes: #{other_year_students.count}"

      # Students not enrolled in any class
      unenrolled_students = all_students.left_joins(:student_class_enrollments)
                                        .where(student_class_enrollments: { id: nil })
      puts "  Students not enrolled in any class: #{unenrolled_students.count}"
    end

    puts "\n=== Summary ==="
    puts "Total schools: #{School.count}"
    puts "Total classes: #{SchoolClass.count}"
    puts "Total students: #{User.joins(:roles).where(roles: { key: 'student' }).count}"
    puts "Total enrollments: #{StudentClassEnrollment.count}"
  end
end
