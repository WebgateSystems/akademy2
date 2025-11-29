class LearningModule < ApplicationRecord
  belongs_to :unit
  has_many :contents, dependent: :destroy

  scope :published, -> { where(published: true) }
  scope :unpublished, -> { where(published: false) }

  def title_with_unit_and_subject
    "#{unit&.subject&.title} > #{unit&.title} > #{title}"
  end
end
