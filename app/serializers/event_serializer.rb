# frozen_string_literal: true

class EventSerializer < ApplicationSerializer
  attributes :id, :event_type, :occurred_at, :created_at, :updated_at
  attribute :user_id, &:user_id

  attribute :user_name do |event|
    [event.user.first_name, event.user.last_name].compact.join(' ').presence || event.user.email if event.user
  end

  attribute :user_email do |event|
    event.user&.email
  end

  attribute :subject_type do |event|
    event.data['subject_type'] || event.data['subject'] || event.event_type
  end

  attribute :subject_id do |event|
    event.data['subject_id'] || event.id
  end

  attribute :subject_owner_id do |event|
    event.data['subject_owner_id']
  end

  attribute :data do |event|
    event.data || {}
  end
end
