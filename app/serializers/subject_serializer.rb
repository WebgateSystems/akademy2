# frozen_string_literal: true

class SubjectSerializer < ApplicationSerializer
  attributes :id, :title, :slug, :order_index, :color_light, :color_dark, :created_at, :updated_at

  attribute :icon_url do |subject|
    subject.icon.url if subject.icon.present?
  end
end
