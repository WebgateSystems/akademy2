# frozen_string_literal: true

FactoryBot.define do
  factory :subject do
    association :school

    title       { FFaker::Education.major }
    sequence(:slug) { |n| "subject-#{n}" }
    order_index { 0 }
  end
end
