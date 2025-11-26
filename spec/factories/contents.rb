# frozen_string_literal: true

FactoryBot.define do
  factory :content do
    association :learning_module
    content_type { 'video' }
    title { FFaker::Lorem.sentence }
    order_index { 0 }
    duration_sec { 120 }
    payload { {} }
  end
end
