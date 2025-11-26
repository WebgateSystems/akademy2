# frozen_string_literal: true

FactoryBot.define do
  factory :quiz_result do
    association :user
    association :learning_module
    score { 85 }
    passed { true }
    completed_at { Time.current }
    details { {} }
  end
end
