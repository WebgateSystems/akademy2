class SchoolClass < ApplicationRecord
  belongs_to :school
  has_many :teacher_class_assignments, dependent: :destroy
  has_many :teachers, through: :teacher_class_assignments, source: :teacher
  has_many :student_class_enrollments, dependent: :destroy
  has_many :students, through: :student_class_enrollments, source: :student

  validates :name, presence: true
  validates :year, presence: true
  validates :join_token, uniqueness: true, allow_nil: true

  before_create :generate_join_token

  # Find class by join token
  # Token format: "xxxxxxxx-xxxx-xxxx" (first 3 sections of UUID)
  def self.find_by_join_token(token)
    return nil if token.blank?

    cleaned_token = token.strip.downcase

    # Extract token from URL if full URL provided
    cleaned_token = cleaned_token.split('/').last if cleaned_token.include?('/')

    # Validate token format (8-4-4 hex pattern for class)
    return nil unless cleaned_token.match?(/\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}\z/)

    find_by(join_token: cleaned_token)
  end

  private

  def generate_join_token
    return if join_token.present?

    # Format: xxxxxxxx-xxxx-xxxx (first 3 segments of UUID)
    loop do
      self.join_token = SecureRandom.uuid.split('-').first(3).join('-')
      break unless SchoolClass.exists?(join_token: join_token)
    end
  end
end
