# frozen_string_literal: true

FactoryBot.define do
  factory :student_video do
    association :user, factory: :user
    association :subject, factory: :subject
    association :school, factory: :school
    title { 'Sample Video' }
    description { 'A sample video description' }
    status { 'pending' }
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/test.mp4'), 'video/mp4') }

    trait :approved do
      status { 'approved' }
      moderated_at { Time.current }
    end

    trait :rejected do
      status { 'rejected' }
      moderated_at { Time.current }
      rejection_reason { 'Video does not meet requirements' }
    end

    trait :with_youtube_url do
      youtube_url { 'https://www.youtube.com/watch?v=test123' }
    end

    trait :with_thumbnail do
      thumbnail { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/test.png'), 'image/png') }
    end
  end
end
