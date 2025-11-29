# frozen_string_literal: true

class UnitSerializer < ApplicationSerializer
  attributes :id, :title, :order_index, :subject_id, :created_at, :updated_at

  attribute :subject_title do |unit|
    unit.subject&.title
  end
end
