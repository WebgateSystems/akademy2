class Unit < ApplicationRecord
  belongs_to :subject
  has_many :learning_modules, dependent: :destroy

  def title_with_subject
    "#{subject&.title} > #{title}"
  end
end
