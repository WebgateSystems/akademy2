class CertificatePdfUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    user = model.user
    school = user&.school
    year = school&.current_academic_year_value

    klass = user&.school_classes&.find_by(year: year)

    klass_id = klass&.id || 'unknown'

    "generated/certs/#{school&.id || 'no-school'}/#{klass_id}"
  end

  def extension_allowlist
    %w[pdf]
  end
end
