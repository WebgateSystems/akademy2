class HeadmasterSerializer < ApplicationSerializer
  attributes :id, :first_name, :last_name, :email, :school_id, :created_at, :updated_at

  attribute :name do |headmaster|
    [headmaster.first_name, headmaster.last_name].compact.join(' ').presence || headmaster.email
  end

  attribute :school_name do |headmaster|
    headmaster.school&.name
  end

  attribute :phone do |headmaster|
    headmaster.metadata&.dig('phone')
  end
end

