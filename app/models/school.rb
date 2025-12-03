class School < ApplicationRecord
  mount_uploader :logo, BaseUuidUploader

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  before_create :generate_join_token

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :city, presence: true
  validates :country, presence: true
  validates :join_token, uniqueness: true, allow_nil: true

  has_many :academic_years, dependent: :destroy

  def current_academic_year
    academic_years.current.first
  end

  def current_academic_year_value
    current_academic_year&.year || '2025/2026'
  end

  # Find school by join token
  # Token format: "xxxx-xxxx-xxxxxxxxxxxx" (last 3 sections of UUID)
  def self.find_by_join_token(token)
    return nil if token.blank?

    cleaned_token = token.strip.downcase

    # Extract token from URL if full URL provided
    cleaned_token = cleaned_token.split('/').last if cleaned_token.include?('/')

    # Validate token format (4-4-12 hex pattern for school)
    return nil unless cleaned_token.match?(/\A[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\z/)

    find_by(join_token: cleaned_token)
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

  def generate_join_token
    return if join_token.present?

    # Format: xxxx-xxxx-xxxxxxxxxxxx (last 3 segments of UUID)
    loop do
      self.join_token = SecureRandom.uuid.split('-').last(3).join('-')
      break unless School.exists?(join_token: join_token)
    end
  end
end
