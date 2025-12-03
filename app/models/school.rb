class School < ApplicationRecord
  mount_uploader :logo, BaseUuidUploader

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :city, presence: true
  validates :country, presence: true

  has_many :academic_years, dependent: :destroy

  def current_academic_year
    academic_years.current.first
  end

  def current_academic_year_value
    current_academic_year&.year || '2025/2026'
  end

  # Join token is first 3 sections of UUID (e.g., "34df7beb-1732-4cd3")
  def join_token
    id.to_s.split('-').first(3).join('-')
  end

  # Find school by join token (first 3 sections of UUID)
  def self.find_by_join_token(token)
    return nil if token.blank?

    # Token format: "xxxxxxxx-xxxx-xxxx" (first 3 sections of UUID)
    cleaned_token = token.strip.downcase

    # Extract token from URL if full URL provided
    cleaned_token = cleaned_token.split('/').last if cleaned_token.include?('/')

    # Validate token format (8-4-4 hex pattern)
    return nil unless cleaned_token.match?(/\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}\z/)

    # Find school where UUID starts with this token
    where('id::text LIKE ?', "#{cleaned_token}%").first
  end

  private

  def generate_slug
    self.slug = name.parameterize
    # Ensure uniqueness
    base_slug = slug
    counter = 1
    while School.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
