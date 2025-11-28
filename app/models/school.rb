class School < ApplicationRecord
  mount_uploader :logo, BaseUuidUploader

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  has_many :subjects, dependent: :destroy
  has_many :school_classes, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :city, presence: true
  validates :country, presence: true

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
