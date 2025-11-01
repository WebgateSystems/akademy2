# frozen_string_literal: true
return if Subscription.exists?

log('Create Subscriptions...')

premium = Plan.find_by!(key: 'premium')
basic   = Plan.find_by!(key: 'basic')

Subscription.create!(
  school: @school_a, plan: premium,
  starts_on: Date.today - 15,
  expires_on: Date.today + 365,
  status: 'active'
)

Subscription.create!(
  school: @school_b, plan: basic,
  starts_on: Date.today - 15,
  expires_on: Date.today + 365,
  status: 'active'
)
