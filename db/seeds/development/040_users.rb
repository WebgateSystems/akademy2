# frozen_string_literal: true

return if User.joins(:roles).where(roles: { key: %w[admin manager] }).exists?

log('Create Global Admins & Managers...')

pwd = 'devpass!'

# Global Admin
@admin = User.create!(
  email: 'sladkowski@webgate.pro', password: pwd, password_confirmation: pwd,
  first_name: 'Jerzy', last_name: 'Admin', locale: 'pl', confirmed_at: Time.current,
  phone: "+48#{rand(500_000_000..999_999_999)}"
)
UserRole.create!(user: @admin, role: Role.find_by!(key: 'admin'), school: @school_a)

# Global Manager
@mgr = User.create!(
  email: 'manager@akademy.local', password: pwd, password_confirmation: pwd,
  first_name: 'Marek', last_name: 'Manager', locale: 'pl', confirmed_at: Time.current,
  phone: "+48#{rand(500_000_000..999_999_999)}"
)
UserRole.create!(user: @mgr, role: Role.find_by!(key: 'manager'), school: @school_a)
