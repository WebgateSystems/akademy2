# frozen_string_literal: true

class StudentVideoLike < ApplicationRecord
  belongs_to :student_video, counter_cache: :likes_count
  belongs_to :user

  validates :user_id, uniqueness: { scope: :student_video_id, message: 'has already liked this video' }
end
