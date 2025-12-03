# frozen_string_literal: true

FactoryBot.define do
  factory :teacher_school_enrollment do
    association :teacher, factory: :user
    association :school
    status { 'pending' }
    joined_at { nil }

    trait :pending do
      status { 'pending' }
    end

    trait :approved do
      status { 'approved' }
      joined_at { Time.current }
    end
  end
end
