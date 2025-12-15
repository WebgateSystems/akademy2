# frozen_string_literal: true

class SubjectCompleteSerializer < ApplicationSerializer
  attributes :id, :title, :slug, :description, :order_index, :color_light, :color_dark, :created_at, :updated_at

  attribute :icon_url do |subject|
    subject.icon.presence&.url
  end

  # Since each subject has one unit, and that unit has one learning_module
  attribute :unit do |subject, params|
    unit = subject.units.first
    next nil unless unit

    learning_module = unit.learning_modules.first
    # Only show published modules (unless admin)
    current_user = params[:current_user] if params
    next nil unless learning_module&.published? || current_user&.admin?

    {
      id: unit.id,
      title: unit.title,
      order_index: unit.order_index,
      learning_module: {
        id: learning_module.id,
        title: learning_module.title,
        order_index: learning_module.order_index,
        published: learning_module.published,
        single_flow: learning_module.single_flow,
        contents: learning_module.contents.sort_by(&:order_index).map do |content|
          {
            id: content.id,
            title: content.title,
            content_type: content.content_type,
            order_index: content.order_index,
            duration_sec: content.duration_sec,
            youtube_url: content.youtube_url,
            payload: content.payload,
            file_url: content.file.presence&.url,
            file_hash: content.file_hash,
            file_format: content.file_format,
            poster_url: content.poster.presence&.url,
            subtitles_url: content.subtitles.presence&.url
          }
        end
      }
    }
  end
end
