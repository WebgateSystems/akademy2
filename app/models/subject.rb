class Subject < ApplicationRecord
  belongs_to :school, optional: true # nil = global subject
  has_many :units, dependent: :destroy

  # Icon jako plik (SVG, PNG, JPG) uploadowany przez CarrierWave
  mount_uploader :icon, BaseUuidUploader

  # Eager loading for destroy to avoid N+1 queries
  def self.with_associations_for_destroy
    includes(units: { learning_modules: :contents })
  end
end
