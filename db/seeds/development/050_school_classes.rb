# frozen_string_literal: true

return if SchoolClass.exists?

log('Create School Classes...')

@class_4b = SchoolClass.create!(
  school: @school_a,
  name: '4B',
  year: '2025/2026',
  qr_token: SecureRandom.uuid,
  metadata: { profile: 'ogólny' }
)

@class_5a = SchoolClass.create!(
  school: @school_a,
  name: '5A',
  year: '2025/2026',
  qr_token: SecureRandom.uuid,
  metadata: { profile: 'mat-fiz' }
)
