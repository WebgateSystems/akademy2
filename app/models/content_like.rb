# frozen_string_literal: true

class ContentLike < ApplicationRecord
  belongs_to :user
  belongs_to :content, counter_cache: :likes_count

  validates :user_id, uniqueness: { scope: :content_id }
end
