# frozen_string_literal: true

FactoryBot.define do
  factory :request_block_rule do
    rule_type { 'ip' }
    value { '192.168.1.1' }
    enabled { true }
    note { 'Test blocking rule' }
    association :created_by, factory: :user

    trait :user_rule do
      rule_type { 'user' }
      value { SecureRandom.uuid }
    end

    trait :cidr_rule do
      rule_type { 'cidr' }
      value { '10.0.0.0/24' }
    end

    trait :disabled do
      enabled { false }
    end
  end
end
