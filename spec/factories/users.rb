FactoryBot.define do
  factory :user do
    email { FFaker::Internet.email }
    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    locale { 'en' }
    password { 'Password1' }
    password_confirmation { 'Password1' }
    phone { "+48#{rand(500_000_000..999_999_999)}" }
    birthdate { Date.new(2000, 1, 1) }
    school { create(:school) }
    confirmed_at { Time.current }

    trait :admin do
      after(:create) do |user|
        admin_role = Role.find_or_create_by!(key: 'admin') { |r| r.name = 'Admin' }
        UserRole.find_or_create_by!(user: user, role: admin_role)
      end
    end

    trait :teacher do
      after(:create) do |user|
        teacher_role = Role.find_or_create_by!(key: 'teacher') { |r| r.name = 'Teacher' }
        UserRole.find_or_create_by!(user: user, role: teacher_role, school: user.school)
      end
    end

    trait :student do
      after(:create) do |user|
        student_role = Role.find_or_create_by!(key: 'student') { |r| r.name = 'Student' }
        UserRole.find_or_create_by!(user: user, role: student_role, school: user.school)
      end
    end
  end
end
