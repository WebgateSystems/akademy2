# frozen_string_literal: true
return if TeacherClassAssignment.exists?

log('Assign Teachers to Classes...')

TeacherClassAssignment.create!(teacher_id: @teacher1.id, school_class: @class_4b, role: 'main')
TeacherClassAssignment.create!(teacher_id: @teacher2.id, school_class: @class_4b, role: 'assistant')
TeacherClassAssignment.create!(teacher_id: @teacher1.id, school_class: @class_5a, role: 'assistant')
