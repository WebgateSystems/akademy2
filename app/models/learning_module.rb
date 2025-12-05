class LearningModule < ApplicationRecord
  belongs_to :unit
  has_many :contents, dependent: :destroy

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  validates :slug, uniqueness: true, allow_nil: true

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  # Use slug for URL if available, otherwise id
  def to_param
    slug.presence || id
  end

  def title_with_unit_and_subject
    "#{unit&.subject&.title} > #{unit&.title} > #{title}"
  end

  private

  def generate_slug
    base_slug = title.parameterize
    self.slug = base_slug
    counter = 1
    while LearningModule.where(slug: slug).where.not(id: id).exists?
      self.slug = "#{base_slug}-#{counter}"
      counter += 1
    end
  end
end
