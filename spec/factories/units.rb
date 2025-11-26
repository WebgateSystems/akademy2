# frozen_string_literal: true

FactoryBot.define do
  factory :unit do
    association :subject
    title { FFaker::Lorem.sentence }
    order_index { 0 }
  end
end
