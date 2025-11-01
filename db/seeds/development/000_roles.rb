# frozen_string_literal: true

return unless Role.count.zero?

log('Create Roles...')

[
  [ 'admin',     'Application admin' ],
  [ 'manager',   'Application manager' ],
  [ 'principal',        'Dyrektor' ],
  [ 'school_manager',   'Manager Szkolny' ],
  [ 'teacher',          'Nauczyciel' ],
  [ 'student',          'Uczeń' ],
  [ 'parent',           'Rodzic' ]
].each do |key, name|
  Role.create!(key:, name:)
end
