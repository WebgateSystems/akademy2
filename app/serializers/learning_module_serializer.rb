# frozen_string_literal: true

class LearningModuleSerializer < ApplicationSerializer
  attributes :id, :title, :order_index, :unit_id, :published, :single_flow, :created_at, :updated_at

  attribute :unit_title do |learning_module|
    learning_module.unit&.title
  end

  attribute :subject_title do |learning_module|
    learning_module.unit&.subject&.title
  end

  attribute :subject_id do |learning_module|
    learning_module.unit&.subject_id
  end

  attribute :contents_count do |learning_module|
    learning_module.contents.count
  end
end
