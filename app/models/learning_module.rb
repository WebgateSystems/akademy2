class LearningModule < ApplicationRecord
  belongs_to :unit
  has_many :contents, dependent: :destroy
end
