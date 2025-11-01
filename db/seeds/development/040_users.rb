# frozen_string_literal: true
return if User.exists?

log('Create Users & assign Roles...')

pwd = 'devpass!'

# Global
@admin = User.create!(
  email: 'sladkowski@webgate.pro', password: pwd, password_confirmation: pwd,
  first_name: 'Jerzy', last_name: 'Admin', locale: 'pl', confirmed_at: Time.current
)
UserRole.create!(user: @admin, role: Role.find_by!(key: 'admin'),   school: @school_a)

@mgr  = User.create!(
  email: 'manager@akademy.local', password: pwd, password_confirmation: pwd,
  first_name: 'Marek', last_name: 'Manager', locale: 'pl', confirmed_at: Time.current
)
UserRole.create!(user: @mgr,  role: Role.find_by!(key: 'manager'), school: @school_a)

# School A
@principal_a = User.create!(
  email: 'dyrektor.sp53@akademy.local', password: pwd, password_confirmation: pwd,
  first_name: 'Dorota', last_name: 'Dyrektor', locale: 'pl',
  school: @school_a, confirmed_at: Time.current
)
UserRole.create!(user: @principal_a, role: Role.find_by!(key: 'principal'), school: @school_a)
UserRole.create!(user: @principal_a, role: Role.find_by!(key: 'parent'),    school: @school_a)

@manager_a = User.create!(
  email: 'manager.sp53@akademy.local', password: pwd, password_confirmation: pwd,
  first_name: 'Michał', last_name: 'Manager', locale: 'pl',
  school: @school_a, confirmed_at: Time.current
)
UserRole.create!(user: @manager_a, role: Role.find_by!(key: 'school_manager'), school: @school_a)
UserRole.create!(user: @manager_a, role: Role.find_by!(key: 'teacher'),        school: @school_a)

@teacher1 = User.create!(
  email: 'nauczyciel.1@akademy.local', password: pwd, password_confirmation: pwd,
  first_name: 'Natalia', last_name: 'Nowak', locale: 'pl',
  school: @school_a, confirmed_at: Time.current
)
UserRole.create!(user: @teacher1, role: Role.find_by!(key: 'teacher'), school: @school_a)
UserRole.create!(user: @teacher1, role: Role.find_by!(key: 'parent'),  school: @school_a)

@teacher2 = User.create!(
  email: 'nauczyciel.2@akademy.local', password: pwd, password_confirmation: pwd,
  first_name: 'Piotr', last_name: 'Polak', locale: 'pl',
  school: @school_a, confirmed_at: Time.current
)
UserRole.create!(user: @teacher2, role: Role.find_by!(key: 'teacher'), school: @school_a)

@student1 = User.create!(
  email: 'uczen.1@akademy.local', password: pwd, password_confirmation: pwd,
  first_name: 'Ola', last_name: 'Olszewska', locale: 'pl',
  school: @school_a, confirmed_at: Time.current
)
UserRole.create!(user: @student1, role: Role.find_by!(key: 'student'), school: @school_a)

@student2 = User.create!(
  email: 'uczen.2@akademy.local', password: pwd, password_confirmation: pwd,
  first_name: 'Bartek', last_name: 'Bąk', locale: 'pl',
  school: @school_a, confirmed_at: Time.current
)
UserRole.create!(user: @student2, role: Role.find_by!(key: 'student'), school: @school_a)

@parent1 = User.create!(
  email: 'rodzic.1@akademy.local', password: pwd, password_confirmation: pwd,
  first_name: 'Rita', last_name: 'Rodzic', locale: 'pl',
  school: @school_a, confirmed_at: Time.current
)
UserRole.create!(user: @parent1, role: Role.find_by!(key: 'parent'), school: @school_a)
