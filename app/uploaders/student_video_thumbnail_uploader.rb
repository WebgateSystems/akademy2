# frozen_string_literal: true

class StudentVideoThumbnailUploader < CarrierWave::Uploader::Base
  storage :file

  # Override storage directory
  def store_dir
    parts = model.id.to_s.scan(/.{1,2}/).first(2).join('/')
    "uploads/student_videos/thumbnails/#{parts}/#{model.id}"
  end

  # Generate unique filename
  def filename
    return if original_filename.blank?

    @filename ||= "thumb_#{SecureRandom.uuid}#{File.extname(original_filename).downcase}"
  end

  # Allowed image formats
  def extension_allowlist
    %w[jpg jpeg png webp]
  end

  # Content type validation
  def content_type_allowlist
    %r{image/}
  end
end
