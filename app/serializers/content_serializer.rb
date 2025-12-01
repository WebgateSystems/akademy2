# frozen_string_literal: true

class ContentSerializer < ApplicationSerializer
  attributes :id, :title, :content_type, :order_index, :learning_module_id, :duration_sec, :youtube_url, :payload,
             :file_hash, :file_format, :created_at, :updated_at

  attribute :learning_module_title do |content|
    content.learning_module&.title
  end

  attribute :file_url do |content|
    content.file.presence&.url
  end

  attribute :poster_url do |content|
    content.poster.presence&.url
  end

  attribute :subtitles_url do |content|
    content.subtitles.presence&.url
  end
end
