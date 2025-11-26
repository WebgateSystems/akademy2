# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    association :user
    association :school
    event_type { 'test_event' }
    data { {} }
    client { 'test' }
    occurred_at { Time.current }
  end
end
