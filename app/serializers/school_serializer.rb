class SchoolSerializer < ApplicationSerializer
  attributes :id, :name, :slug, :address, :city, :postcode, :country, :phone, :email, :homepage, :logo, :created_at,
             :updated_at

  attribute :logo_url do |school|
    school.logo.presence&.url
  end
end
