# frozen_string_literal: true

return if User.joins(:roles).where(roles: { key: %w[principal school_manager] }).exists?

log('Create Principals & School Managers...')

pwd = 'devpass!'

# School A (SP53) - Principal
@principal_a = User.create!(
  email: 'dyrektor.sp53@akademy.local', password: pwd, password_confirmation: pwd,
  first_name: 'Małgorzata', last_name: 'Onasch-Ptaszyńska', locale: 'pl',
  school: @school_a, confirmed_at: Time.current,
  metadata: { phone: '+48 58 622 22 24' }
)
UserRole.create!(user: @principal_a, role: Role.find_by!(key: 'principal'), school: @school_a)

# School A (SP53) - School Manager
@manager_a = User.create!(
  email: 'manager.sp53@akademy.local', password: pwd, password_confirmation: pwd,
  first_name: 'Michał', last_name: 'Manager', locale: 'pl',
  school: @school_a, confirmed_at: Time.current
)
UserRole.create!(user: @manager_a, role: Role.find_by!(key: 'school_manager'), school: @school_a)
UserRole.create!(user: @manager_a, role: Role.find_by!(key: 'teacher'), school: @school_a)

# School B (SP18) - Principal (from https://sp18.gdynia.pl/nauczyciele,57,pl)
@principal_b = User.create!(
  email: 'sekretariat@sp18.edu.gdynia.pl', password: pwd, password_confirmation: pwd,
  first_name: 'Eliza', last_name: 'Zaborowska-Kempa', locale: 'pl',
  school: @school_b, confirmed_at: Time.current,
  metadata: { phone: '+48 58 620 69 43' }
)
UserRole.create!(user: @principal_b, role: Role.find_by!(key: 'principal'), school: @school_b)

# School B (SP18) - Vice Principal 1
@vice_principal_b1 = User.create!(
  email: 'kszmidt@sp18.edu.gdynia.pl', password: pwd, password_confirmation: pwd,
  first_name: 'Krystyna', last_name: 'Szmidt', locale: 'pl',
  school: @school_b, confirmed_at: Time.current
)
UserRole.create!(user: @vice_principal_b1, role: Role.find_by!(key: 'school_manager'), school: @school_b)

# School B (SP18) - Vice Principal 2
@vice_principal_b2 = User.create!(
  email: 'apiwowska@sp18.edu.gdynia.pl', password: pwd, password_confirmation: pwd,
  first_name: 'Anna', last_name: 'Piwowska', locale: 'pl',
  school: @school_b, confirmed_at: Time.current
)
UserRole.create!(user: @vice_principal_b2, role: Role.find_by!(key: 'school_manager'), school: @school_b)
