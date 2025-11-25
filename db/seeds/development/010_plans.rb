# frozen_string_literal: true

return unless Plan.count.zero?

log('Create Plans...')

Plan.create!(
  key: 'free', name: 'Free',
  limits: { max_students: 50 },
  features: { csv_export: false, offline_download: true, webinars: false }
)

Plan.create!(
  key: 'basic', name: 'Basic',
  limits: { max_students: 200 },
  features: { csv_export: true, offline_download: true, webinars: false }
)

Plan.create!(
  key: 'premium', name: 'Premium',
  limits: { max_students: 2000 },
  features: { csv_export: true, offline_download: true, webinars: true }
)
