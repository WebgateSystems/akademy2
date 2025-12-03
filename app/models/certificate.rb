class Certificate < ApplicationRecord
  belongs_to :quiz_result

  mount_uploader :pdf, CertificatePdfUploader

  delegate :user, :learning_module, to: :quiz_result
end
