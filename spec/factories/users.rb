FactoryBot.define do
  factory :user do
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    locale { 'en' }
    password { 'Password1' }
    password_confirmation { 'Password1' }
    phone { FFaker::PhoneNumber.phone_number }
    birthdate { Date.new(2000, 1, 1) }
    school { create(:school) }
  end
end
