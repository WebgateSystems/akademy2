# frozen_string_literal: true

FactoryBot.define do
  factory :learning_module do
    association :unit
    title { FFaker::Lorem.sentence }
    order_index { 0 }
  end
end
