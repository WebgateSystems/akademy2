class SchoolClass < ApplicationRecord
  belongs_to :school
  has_many :teacher_class_assignments, dependent: :destroy
  has_many :teachers, through: :teacher_class_assignments, source: :teacher
  has_many :student_class_enrollments, dependent: :destroy
  has_many :students, through: :student_class_enrollments, source: :student

  validates :name, presence: true
  validates :year, presence: true

  # Join token is first 3 sections of UUID (e.g., "34df7beb-1732-4cd3")
  def join_token
    id.to_s.split('-').first(3).join('-')
  end

  # Find class by join token (first 3 sections of UUID)
  def self.find_by_join_token(token)
    return nil if token.blank?

    # Token format: "xxxxxxxx-xxxx-xxxx" (first 3 sections of UUID)
    cleaned_token = token.strip.downcase

    # Extract token from URL if full URL provided
    cleaned_token = cleaned_token.split('/').last if cleaned_token.include?('/')

    # Validate token format (8-4-4 hex pattern)
    return nil unless cleaned_token.match?(/\A[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}\z/)

    # Find class where UUID starts with this token
    where('id::text LIKE ?', "#{cleaned_token}%").first
  end
end
