# frozen_string_literal: true

FactoryBot.define do
  factory :parent_student_link do
    association :parent, factory: :user
    association :student, factory: :user
    relation { 'other' }

    trait :mother do
      relation { 'mother' }
    end

    trait :father do
      relation { 'father' }
    end

    trait :guardian do
      relation { 'guardian' }
    end
  end
end
