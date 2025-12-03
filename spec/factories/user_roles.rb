FactoryBot.define do
  factory :user_role do
    user
    role
    school { nil }
  end
end
