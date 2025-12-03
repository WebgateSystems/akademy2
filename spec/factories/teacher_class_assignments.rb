FactoryBot.define do
  factory :teacher_class_assignment do
    association :teacher, factory: :user
    school_class
    role { 'teacher' }
  end
end
