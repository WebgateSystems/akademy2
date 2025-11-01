class Content < ApplicationRecord
  belongs_to :learning_module
  mount_uploader :file, BaseUuidUploader
  mount_uploader :poster, BaseUuidUploader
  mount_uploader :subtitles, BaseUuidUploader
end
