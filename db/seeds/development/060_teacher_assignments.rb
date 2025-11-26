# frozen_string_literal: true

return if TeacherClassAssignment.exists?

log('Assign Teachers to Classes...')

# Assign teachers to classes based on metadata
teachers = User.joins(:roles).where(roles: { key: 'teacher' })

teachers.each do |teacher|
  class_name = teacher.metadata&.dig('class')
  next unless class_name

  # Handle multiple classes (e.g., "4b, 5na")
  class_names = class_name.split(',').map(&:strip)

  class_names.each do |cn|
    school_class = SchoolClass.find_by(school: teacher.school, name: cn)
    next unless school_class

    # Check if assignment already exists
    next if TeacherClassAssignment.exists?(teacher_id: teacher.id, school_class_id: school_class.id)

    # Assign as main teacher for the class
    TeacherClassAssignment.create!(
      teacher_id: teacher.id,
      school_class: school_class,
      role: 'main'
    )
  end
end

# Assign some additional teachers as assistants (randomly)
classes = SchoolClass.all
classes.each do |school_class|
  # Get teachers from the same school who are not already assigned
  available_teachers = User.joins(:roles)
                           .where(roles: { key: 'teacher' })
                           .where(school: school_class.school)
                           .where.not(id: TeacherClassAssignment.where(school_class: school_class).select(:teacher_id))
                           .limit(rand(0..2))

  available_teachers.each do |teacher|
    TeacherClassAssignment.create!(
      teacher_id: teacher.id,
      school_class: school_class,
      role: 'assistant'
    )
  end
end
