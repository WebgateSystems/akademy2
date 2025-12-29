# frozen_string_literal: true

FactoryBot.define do
  factory :webinar_registration do
    first_name { 'Jan' }
    last_name { 'Kowalski' }
    sequence(:email) { |n| "uczestnik#{n}@example.com" }
    webinar_id { '2025-12-29-akademy-intro' }
    position { 'Nauczyciel' }
    school_name { 'SP nr 1 w Warszawie' }
    phone { '+48 123 456 789' }
  end
end
