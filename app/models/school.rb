class School < ApplicationRecord
  mount_uploader :logo, BaseUuidUploader
end
