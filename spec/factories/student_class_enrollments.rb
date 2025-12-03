FactoryBot.define do
  factory :student_class_enrollment do
    association :student, factory: :user
    school_class
    status { 'pending' }
  end
end
