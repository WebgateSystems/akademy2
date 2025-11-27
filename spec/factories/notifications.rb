# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    notification_type { 'teacher_awaiting_approval' }
    title { 'New teacher joined' }
    # rubocop:disable I18n/GetText/DecorateString
    message { 'John Doe is awaiting approval.' }
    # rubocop:enable I18n/GetText/DecorateString
    target_role { 'school_manager' }
    school
    user
    metadata { { teacher_id: SecureRandom.uuid } }
    read_at { nil }
    resolved_at { nil }

    trait :read do
      read_at { Time.current }
      read_by_user { association :user }
    end

    trait :resolved do
      resolved_at { Time.current }
    end

    trait :for_principal do
      target_role { 'principal' }
    end

    trait :for_admin do
      target_role { 'admin' }
    end

    trait :student_awaiting_approval do
      notification_type { 'student_awaiting_approval' }
      title { 'New student joined' }
      # rubocop:disable I18n/GetText/DecorateString
      message { 'Jane Doe is awaiting approval.' }
      # rubocop:enable I18n/GetText/DecorateString
      metadata { { student_id: SecureRandom.uuid } }
    end

    trait :report_ready do
      notification_type { 'report_ready' }
      title { 'Report ready' }
      # rubocop:disable I18n/GetText/DecorateString
      message { 'Monthly report is ready for review.' }
      # rubocop:enable I18n/GetText/DecorateString
      metadata { { report_id: SecureRandom.uuid } }
    end
  end
end
